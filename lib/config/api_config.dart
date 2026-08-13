// ---------------------------------------------------------------------------
// api_config.dart
// ---------------------------------------------------------------------------
// Centralised configuration for the TMDb API.
//
// All network-related constants (base URL, API key, default query parameters)
// live here so they can be changed in a single place without touching any
// service or repository code.
// ---------------------------------------------------------------------------

class ApiConfig {
  // Private constructor — this class should never be instantiated.
  ApiConfig._();

  // ── Base URL ──────────────────────────────────────────────────────────────
  /// The root URL for every TMDb REST endpoint.
  static const String baseUrl = 'https://api.themoviedb.org/3';

  // ── Authentication ────────────────────────────────────────────────────────
  /// Your TMDb v3 API key.
  ///
  /// ⚠️  In production, prefer loading this from an environment variable or a
  ///     secure secrets manager (e.g. `--dart-define=TMDB_API_KEY=...`).
  static const String apiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '');

  // ── Defaults ──────────────────────────────────────────────────────────────
  /// Default language tag appended to every request.
  static const String defaultLanguage = 'en-US';

  /// Default page number for paginated endpoints.
  static const int defaultPage = 1;

  // ── Image CDN ─────────────────────────────────────────────────────────────
  /// Base URL for TMDb poster/backdrop images.
  ///
  /// Append a size prefix (e.g. `w500`) and the file path returned by the API
  /// to build the full image URL:
  ///   `$imageBaseUrl/w500$posterPath`
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  /// Commonly used poster width. TMDb supports w92, w154, w185, w342, w500,
  /// w780, and `original`.
  static const String posterSize = 'w500';

  /// Profile image width for cast photos.
  /// TMDb supports w45, w185, h632, and `original`.
  static const String profileSize = 'w185';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  /// Maximum time to wait for a response before aborting the request.
  static const Duration requestTimeout = Duration(seconds: 15);
}
