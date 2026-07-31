// ---------------------------------------------------------------------------
// actor_detail.dart
// ---------------------------------------------------------------------------
// Data model representing detailed information about a person (actor/actress)
// returned by the TMDb `/person/{person_id}` endpoint.
//
// Includes a factory constructor for JSON deserialization and convenience
// getters for image URLs and formatted dates.
// ---------------------------------------------------------------------------

import '../config/api_config.dart';

class ActorDetail {
  /// Unique TMDb identifier for this person.
  final int id;

  /// The actor / actress display name.
  final String name;

  /// Full biography text. May be empty for lesser-known actors.
  final String biography;

  /// Date of birth as an ISO-8601 string (e.g. `1963-06-09`), or `null`.
  final String? birthday;

  /// Date of death as an ISO-8601 string, or `null` if still alive.
  final String? deathday;

  /// Place of birth (e.g. `Owensboro, Kentucky, USA`), or `null`.
  final String? placeOfBirth;

  /// Relative path to the profile image on the TMDb CDN.
  final String? profilePath;

  /// Known-for department (e.g. `Acting`, `Directing`).
  final String knownForDepartment;

  /// TMDb popularity score.
  final double popularity;

  const ActorDetail({
    required this.id,
    required this.name,
    required this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.profilePath,
    required this.knownForDepartment,
    required this.popularity,
  });

  // ── JSON Deserialization ──────────────────────────────────────────────────

  /// Creates an [ActorDetail] instance from a decoded JSON map.
  ///
  /// Provides sensible defaults for missing or null fields so the model
  /// never throws during construction.
  factory ActorDetail.fromJson(Map<String, dynamic> json) {
    return ActorDetail(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Unknown',
      biography: (json['biography'] as String?) ?? '',
      birthday: json['birthday'] as String?,
      deathday: json['deathday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      profilePath: json['profile_path'] as String?,
      knownForDepartment:
          (json['known_for_department'] as String?) ?? 'Acting',
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ── Convenience Getters ───────────────────────────────────────────────────

  /// Fully-qualified URL for the profile image at original resolution.
  ///
  /// Returns `null` when [profilePath] is unavailable.
  String? get fullProfileUrl => profilePath != null
      ? '${ApiConfig.imageBaseUrl}/h632$profilePath'
      : null;

  /// Fully-qualified URL for the profile image at the standard size.
  String? get fullProfileUrlSmall => profilePath != null
      ? '${ApiConfig.imageBaseUrl}/${ApiConfig.profileSize}$profilePath'
      : null;

  /// Returns a formatted birth date string (e.g. "June 9, 1963").
  /// Returns `null` if [birthday] is not available.
  String? get formattedBirthday {
    if (birthday == null || birthday!.isEmpty) return null;
    try {
      final date = DateTime.parse(birthday!);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return birthday;
    }
  }

  /// Calculates the actor's age based on [birthday] (and [deathday] if deceased).
  int? get age {
    if (birthday == null || birthday!.isEmpty) return null;
    try {
      final birth = DateTime.parse(birthday!);
      final end = deathday != null && deathday!.isNotEmpty
          ? DateTime.parse(deathday!)
          : DateTime.now();
      int years = end.year - birth.year;
      if (end.month < birth.month ||
          (end.month == birth.month && end.day < birth.day)) {
        years--;
      }
      return years;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'ActorDetail(id: $id, name: $name)';
}
