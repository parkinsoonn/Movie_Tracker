// ---------------------------------------------------------------------------
// watchlist_service.dart
// ---------------------------------------------------------------------------
// Reactive Firestore service for the Watchlist feature.
//
// Architecture:
//   • A SINGLE Firestore snapshot listener (`getWatchlistStream`) powers both
//     the Watchlist Screen and the toggle button. This keeps Firebase reads
//     minimal — one listener per active screen, not one per movie.
//   • `getGroupedWatchlistStream` derives genre-grouped data from the same
//     stream via `map()` — zero additional Firestore reads.
//   • `isInWatchlist` uses a dedicated single-document listener for the
//     toggle button on the Detail Screen. This is lightweight because
//     Firestore only sends deltas for individual documents.
//   • `toggleWatchlist` performs an atomic check-and-write: if the document
//     exists it deletes, otherwise it creates. Both operations trigger the
//     snapshot listener, so all StreamBuilders update instantly.
// ---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/movie.dart';
import '../models/watchlist_movie.dart';

class WatchlistService {
  // ── Dependencies ──────────────────────────────────────────────────────────

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WatchlistService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Reference to the current user's watchlist subcollection.
  CollectionReference get _watchlistCol {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user.');
    return _firestore.collection('users').doc(uid).collection('watchlist');
  }

  // ── TMDb Genre Map ────────────────────────────────────────────────────────

  /// Static lookup from TMDb genre ID → display name.
  ///
  /// This avoids an API call to `/genre/movie/list`. The TMDb genre set is
  /// stable and rarely changes, so a hardcoded map is the most cost-effective
  /// approach.
  static const Map<int, String> genreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  /// Returns the display name for a TMDb genre ID.
  static String genreName(int id) => genreMap[id] ?? 'Other';

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Real-time stream of ALL watchlisted movies, ordered by most recently
  /// added. This is the single source of truth for the Watchlist Screen.
  ///
  /// Cost: 1 Firestore listener (billed per document in the initial read,
  /// then only per changed document on updates).
  Stream<List<WatchlistMovie>> getWatchlistStream() {
    return _watchlistCol
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WatchlistMovie.fromFirestore(doc))
            .toList());
  }

  /// Derives a genre-grouped map from the flat watchlist stream.
  ///
  /// Each movie appears under every genre it belongs to (a movie with
  /// genreIds [28, 878] appears under both "Action" and "Sci-Fi").
  /// Movies with no genres go under "Other".
  ///
  /// Cost: 0 additional Firestore reads — pure client-side transformation.
  Stream<Map<String, List<WatchlistMovie>>> getGroupedWatchlistStream() {
    return getWatchlistStream().map((movies) {
      final Map<String, List<WatchlistMovie>> grouped = {};

      for (final movie in movies) {
        if (movie.genreIds.isEmpty) {
          grouped.putIfAbsent('Other', () => []).add(movie);
        } else {
          for (final genreId in movie.genreIds) {
            final name = genreName(genreId);
            grouped.putIfAbsent(name, () => []).add(movie);
          }
        }
      }

      // Sort genre keys alphabetically for consistent ordering.
      final sorted = Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      return sorted;
    });
  }

  /// Lightweight single-document listener that emits `true` when the given
  /// movie is in the watchlist, `false` otherwise.
  ///
  /// Used by [WatchlistToggleButton] on the Detail Screen. Since this
  /// listens to only ONE document, it costs minimal Firestore reads.
  Stream<bool> isInWatchlist(int movieId) {
    return _watchlistCol
        .doc(movieId.toString())
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ── Write Operations ──────────────────────────────────────────────────────

  /// Atomic toggle: adds the movie if absent, removes it if present.
  ///
  /// Both the Watchlist Screen (via `getWatchlistStream`) and the Detail
  /// Screen toggle button (via `isInWatchlist`) will update instantly
  /// because they listen to Firestore snapshots on the same collection.
  Future<void> toggleWatchlist(Movie movie) async {
    final docRef = _watchlistCol.doc(movie.id.toString());
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      final watchlistMovie = WatchlistMovie(
        movieId: movie.id,
        title: movie.title,
        posterPath: movie.posterPath,
        genreIds: movie.genreIds,
        voteAverage: movie.voteAverage,
        releaseDate: movie.releaseDate,
        addedAt: DateTime.now(),
      );
      await docRef.set(watchlistMovie.toMap());
    }
  }

  /// Explicitly adds a movie to the watchlist.
  Future<void> addToWatchlist(Movie movie) async {
    final watchlistMovie = WatchlistMovie(
      movieId: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      genreIds: movie.genreIds,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
      addedAt: DateTime.now(),
    );
    await _watchlistCol
        .doc(movie.id.toString())
        .set(watchlistMovie.toMap());
  }

  /// Explicitly removes a movie from the watchlist.
  Future<void> removeFromWatchlist(int movieId) async {
    await _watchlistCol.doc(movieId.toString()).delete();
  }
}
