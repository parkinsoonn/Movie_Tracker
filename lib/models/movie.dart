// ---------------------------------------------------------------------------
// movie.dart
// ---------------------------------------------------------------------------
// Data model representing a single movie returned by the TMDb API.
//
// Includes a factory constructor for JSON deserialization and a helper
// getter to build the full poster image URL.
// ---------------------------------------------------------------------------

import '../config/api_config.dart';

class Movie {
  /// Unique TMDb identifier for this movie.
  final int id;

  /// The movie's display title.
  final String title;

  /// A short plot summary. May be empty for some entries.
  final String overview;

  /// Relative path to the poster image on the TMDb CDN.
  /// Example: `/kqjL17yufvn9OVLyXYpvtyrFfak.jpg`
  final String? posterPath;

  /// Relative path to a widescreen backdrop image.
  final String? backdropPath;

  /// Average user rating on a 0–10 scale.
  final double voteAverage;

  /// Total number of user votes/ratings.
  final int voteCount;

  /// Release date as an ISO-8601 string (e.g. `2025-06-20`).
  final String? releaseDate;

  /// TMDb popularity score (higher = more popular right now).
  final double popularity;

  /// List of genre IDs associated with this movie.
  final List<int> genreIds;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    required this.popularity,
    required this.genreIds,
  });

  // ── JSON Deserialization ──────────────────────────────────────────────────

  /// Creates a [Movie] instance from a decoded JSON map.
  ///
  /// Defaults are provided for nullable / potentially missing fields so that
  /// the model never throws during construction — invalid data is silently
  /// replaced with sensible fallbacks.
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? 'Unknown Title',
      overview: (json['overview'] as String?) ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: (json['vote_count'] as int?) ?? 0,
      releaseDate: json['release_date'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const <int>[],
    );
  }

  // ── Convenience Getters ───────────────────────────────────────────────────

  /// Fully-qualified URL for the movie poster image at the configured size.
  ///
  /// Returns `null` when [posterPath] is unavailable.
  String? get fullPosterUrl => posterPath != null
      ? '${ApiConfig.imageBaseUrl}/${ApiConfig.posterSize}$posterPath'
      : null;

  /// Fully-qualified URL for the backdrop image at original resolution.
  String? get fullBackdropUrl => backdropPath != null
      ? '${ApiConfig.imageBaseUrl}/original$backdropPath'
      : null;

  @override
  String toString() => 'Movie(id: $id, title: $title)';
}
