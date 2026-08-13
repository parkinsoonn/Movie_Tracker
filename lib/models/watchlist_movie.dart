// ---------------------------------------------------------------------------
// watchlist_movie.dart
// ---------------------------------------------------------------------------
// Data model for a movie in the user's watchlist.
//
// Stored in `users/{uid}/watchlist/{movieId}`. Includes `genreIds` so that
// the Watchlist Screen can group movies by genre client-side without a
// second TMDb API call or multiple Firestore queries.
//
// The `fromMovie()` factory allows seamless conversion from the existing
// [Movie] model when the user taps "Add to Watchlist" on the detail screen.
// ---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_config.dart';

class WatchlistMovie {
  /// TMDb movie identifier.
  final int movieId;

  /// The movie's display title.
  final String title;

  /// Relative poster path from TMDb CDN.
  final String? posterPath;

  /// TMDb genre IDs — used for client-side category grouping.
  final List<int> genreIds;

  /// Average community rating (0–10).
  final double voteAverage;

  /// ISO-8601 release date string (e.g. `2025-06-20`).
  final String? releaseDate;

  /// Timestamp when the user added this movie to their watchlist.
  final DateTime addedAt;

  const WatchlistMovie({
    required this.movieId,
    required this.title,
    this.posterPath,
    required this.genreIds,
    required this.voteAverage,
    this.releaseDate,
    required this.addedAt,
  });

  // ── Firestore Serialization ───────────────────────────────────────────────

  /// Creates a [WatchlistMovie] from a Firestore document snapshot.
  factory WatchlistMovie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WatchlistMovie(
      movieId: (data['movieId'] as num?)?.toInt() ?? 0,
      title: (data['title'] as String?) ?? 'Unknown Title',
      posterPath: data['posterPath'] as String?,
      genreIds: (data['genreIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
      releaseDate: data['releaseDate'] as String?,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this model to a Firestore-compatible map for writes.
  Map<String, dynamic> toMap() => {
        'movieId': movieId,
        'title': title,
        'posterPath': posterPath,
        'genreIds': genreIds,
        'voteAverage': voteAverage,
        'releaseDate': releaseDate,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  // ── Convenience ───────────────────────────────────────────────────────────

  /// Fully-qualified poster URL at the configured size.
  String? get fullPosterUrl => posterPath != null
      ? '${ApiConfig.imageBaseUrl}/${ApiConfig.posterSize}$posterPath'
      : null;

  /// Release year extracted from [releaseDate], or empty string.
  String get year =>
      releaseDate != null && releaseDate!.length >= 4
          ? releaseDate!.substring(0, 4)
          : '';
}
