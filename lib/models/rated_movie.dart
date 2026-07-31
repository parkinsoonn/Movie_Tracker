// ---------------------------------------------------------------------------
// rated_movie.dart
// ---------------------------------------------------------------------------
// Data model for a movie the user has rated.
//
// Stored in `users/{uid}/rated_movies/{movieId}`. Extends the watched concept
// with a `rating` field (0.0–10.0 scale) and a separate `ratedAt` timestamp.
// ---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_config.dart';

class RatedMovie {
  /// TMDb movie identifier.
  final int movieId;

  /// The movie's display title.
  final String title;

  /// Relative poster path from TMDb CDN.
  final String? posterPath;

  /// The user's personal rating on a 0.0–10.0 scale.
  final double rating;

  /// Timestamp when the user submitted this rating.
  final DateTime ratedAt;

  const RatedMovie({
    required this.movieId,
    required this.title,
    this.posterPath,
    required this.rating,
    required this.ratedAt,
  });

  // ── Firestore Serialization ───────────────────────────────────────────────

  /// Creates a [RatedMovie] from a Firestore document snapshot.
  factory RatedMovie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RatedMovie(
      movieId: (data['movieId'] as num?)?.toInt() ?? 0,
      title: (data['title'] as String?) ?? 'Unknown Title',
      posterPath: data['posterPath'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratedAt: (data['ratedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this model to a Firestore-compatible map for writes.
  Map<String, dynamic> toMap() => {
        'movieId': movieId,
        'title': title,
        'posterPath': posterPath,
        'rating': rating,
        'ratedAt': Timestamp.fromDate(ratedAt),
      };

  // ── Convenience ───────────────────────────────────────────────────────────

  /// Fully-qualified poster URL at the configured size.
  String? get fullPosterUrl => posterPath != null
      ? '${ApiConfig.imageBaseUrl}/${ApiConfig.posterSize}$posterPath'
      : null;

  /// Returns the rating formatted as "8.5 / 10".
  String get formattedRating => '${rating.toStringAsFixed(1)} / 10';
}
