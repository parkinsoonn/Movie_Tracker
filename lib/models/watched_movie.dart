// ---------------------------------------------------------------------------
// watched_movie.dart
// ---------------------------------------------------------------------------
// Lightweight data model for a movie in the user's "Watched" list.
//
// Each document in the Firestore `users/{uid}/watched_movies` subcollection
// maps 1:1 to this model. The document ID equals the stringified TMDb movieId,
// ensuring idempotent writes (marking the same movie twice is a no-op).
// ---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_config.dart';

class WatchedMovie {
  /// TMDb movie identifier.
  final int movieId;

  /// The movie's display title.
  final String title;

  /// Relative poster path from TMDb CDN (e.g. `/kqjL17y...jpg`).
  final String? posterPath;

  /// Timestamp when the user marked this movie as watched.
  final DateTime addedAt;

  const WatchedMovie({
    required this.movieId,
    required this.title,
    this.posterPath,
    required this.addedAt,
  });

  // ── Firestore Serialization ───────────────────────────────────────────────

  /// Creates a [WatchedMovie] from a Firestore document snapshot.
  ///
  /// Falls back to sensible defaults for missing fields so that the app
  /// never crashes on incomplete data.
  factory WatchedMovie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WatchedMovie(
      movieId: (data['movieId'] as num?)?.toInt() ?? 0,
      title: (data['title'] as String?) ?? 'Unknown Title',
      posterPath: data['posterPath'] as String?,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this model to a Firestore-compatible map for writes.
  Map<String, dynamic> toMap() => {
        'movieId': movieId,
        'title': title,
        'posterPath': posterPath,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  // ── Convenience ───────────────────────────────────────────────────────────

  /// Fully-qualified poster URL at the configured size.
  String? get fullPosterUrl => posterPath != null
      ? '${ApiConfig.imageBaseUrl}/${ApiConfig.posterSize}$posterPath'
      : null;
}
