// ---------------------------------------------------------------------------
// cast.dart
// ---------------------------------------------------------------------------
// Data model representing a single cast member returned by the TMDb
// `/movie/{movie_id}/credits` endpoint.
//
// Includes a factory constructor for JSON deserialization and a helper
// getter to build the full profile image URL.
// ---------------------------------------------------------------------------

import '../config/api_config.dart';

class Cast {
  /// Unique TMDb identifier for this person.
  final int id;

  /// The actor / actress display name.
  final String name;

  /// The character name they play in the movie.
  final String character;

  /// Relative path to the profile image on the TMDb CDN.
  /// Example: `/kqjL17yufvn9OVLyXYpvtyrFfak.jpg`
  ///
  /// May be `null` when the person has no uploaded photo.
  final String? profilePath;

  /// Ordering index returned by TMDb — lower values appear first (lead
  /// actors before supporting cast).
  final int order;

  const Cast({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
    required this.order,
  });

  // ── JSON Deserialization ────────────────────────────────────────────────

  /// Creates a [Cast] instance from a decoded JSON map.
  ///
  /// Provides sensible defaults for missing or null fields so the model
  /// never throws during construction.
  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Unknown',
      character: (json['character'] as String?) ?? '',
      profilePath: json['profile_path'] as String?,
      order: (json['order'] as int?) ?? 999,
    );
  }

  // ── Convenience Getters ─────────────────────────────────────────────────

  /// Fully-qualified URL for the profile image at the configured size.
  ///
  /// Returns `null` when [profilePath] is unavailable.
  String? get fullProfileUrl => profilePath != null
      ? '${ApiConfig.imageBaseUrl}/${ApiConfig.profileSize}$profilePath'
      : null;

  @override
  String toString() => 'Cast(id: $id, name: $name, character: $character)';
}
