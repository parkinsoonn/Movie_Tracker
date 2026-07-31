// ---------------------------------------------------------------------------
// movie_service.dart
// ---------------------------------------------------------------------------
// Service layer responsible for communicating with the TMDb REST API.
//
// This class is the **single source of truth** for all movie-related network
// calls.  It:
//   • Builds endpoint URIs using [ApiConfig].
//   • Performs HTTP GET requests via the `http` package.
//   • Maps raw JSON responses into strongly-typed [Movie] models.
//   • Translates every possible failure into a typed [ApiException].
//
// Usage:
//   final service = MovieService();
//   final movies  = await service.fetchPopularMovies();
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/actor_detail.dart';
import '../models/cast.dart';
import '../models/movie.dart';
import 'api_exception.dart';

class MovieService {
  // ── Dependencies ──────────────────────────────────────────────────────────

  /// HTTP client used for every request.
  ///
  /// Accepting an [http.Client] via the constructor makes this service easily
  /// testable — pass a `MockClient` in unit tests to avoid real network calls.
  final http.Client _client;

  /// Creates a [MovieService].
  ///
  /// [client] defaults to a fresh [http.Client] if not provided.
  MovieService({http.Client? client}) : _client = client ?? http.Client();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetches a paginated list of currently popular movies from TMDb.
  ///
  /// * [page] — the page number to retrieve (1-indexed, defaults to 1).
  /// * [language] — BCP-47 language tag (defaults to `en-US`).
  ///
  /// Returns a `List<Movie>` on success.
  ///
  /// Throws a subtype of [ApiException] on failure:
  /// - [NetworkException]         — no internet / DNS failure
  /// - [RequestTimeoutException]  — request exceeded the timeout
  /// - [ServerException]          — non-200 HTTP status
  /// - [DataParsingException]     — unexpected response format
  Future<List<Movie>> fetchPopularMovies({
    int page = ApiConfig.defaultPage,
    String language = ApiConfig.defaultLanguage,
  }) async {
    // Build the full endpoint URI with query parameters.
    final uri = Uri.parse('${ApiConfig.baseUrl}/movie/popular').replace(
      queryParameters: {
        'api_key': ApiConfig.apiKey,
        'language': language,
        'page': page.toString(),
      },
    );

    // Delegate to the shared GET helper and parse the result list.
    final Map<String, dynamic> body = await _get(uri);
    return _parseMovieList(body);
  }

  /// Fetches movies from TMDb's `/discover/movie` endpoint with optional
  /// genre and year filters.
  ///
  /// * [genreIds] — list of TMDb genre IDs to include (comma-joined).
  /// * [year] — restrict results to a specific primary release year.
  /// * [page] — page number for pagination (1-indexed).
  ///
  /// When no filters are active, prefer [fetchPopularMovies] instead, as
  /// `/movie/popular` uses TMDb's dedicated popularity ranking.
  Future<List<Movie>> fetchDiscoverMovies({
    List<int>? genreIds,
    int? year,
    int page = ApiConfig.defaultPage,
    String language = ApiConfig.defaultLanguage,
  }) async {
    // Build query params — only include filter keys when values exist.
    final Map<String, String> queryParams = {
      'api_key': ApiConfig.apiKey,
      'language': language,
      'page': page.toString(),
      'sort_by': 'popularity.desc',
    };

    // TMDb accepts a comma-separated list of genre IDs.
    if (genreIds != null && genreIds.isNotEmpty) {
      queryParams['with_genres'] = genreIds.join(',');
    }

    // Filter by exact primary release year.
    if (year != null) {
      queryParams['primary_release_year'] = year.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/discover/movie').replace(
      queryParameters: queryParams,
    );

    final Map<String, dynamic> body = await _get(uri);
    return _parseMovieList(body);
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Fetches complete details for a single movie by its TMDb ID.
  Future<Movie> fetchMovieDetails({
    required int movieId,
    String language = ApiConfig.defaultLanguage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/movie/$movieId').replace(
      queryParameters: {
        'api_key': ApiConfig.apiKey,
        'language': language,
      },
    );

    final Map<String, dynamic> body = await _get(uri);
    return Movie.fromJson(body);
  }

  /// Fetches the cast list for a given movie from the TMDb
  /// `/movie/{movie_id}/credits` endpoint.
  ///
  /// * [movieId] — the TMDb movie ID.
  /// * [maxCast] — maximum number of cast members to return (defaults to 20).
  ///
  /// Returns a `List<Cast>` sorted by [Cast.order] (lead actors first).
  ///
  /// Throws a subtype of [ApiException] on failure (same as other methods).
  Future<List<Cast>> fetchMovieCredits({
    required int movieId,
    int maxCast = 20,
    String language = ApiConfig.defaultLanguage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/movie/$movieId/credits').replace(
      queryParameters: {
        'api_key': ApiConfig.apiKey,
        'language': language,
      },
    );

    final Map<String, dynamic> body = await _get(uri);
    return _parseCastList(body, maxCast: maxCast);
  }

  /// Fetches detailed information about an actor from the TMDb
  /// `/person/{person_id}` endpoint.
  ///
  /// Returns an [ActorDetail] containing biography, birth info, and photo.
  ///
  /// Throws a subtype of [ApiException] on failure.
  Future<ActorDetail> fetchActorDetails({
    required int personId,
    String language = ApiConfig.defaultLanguage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/person/$personId').replace(
      queryParameters: {
        'api_key': ApiConfig.apiKey,
        'language': language,
      },
    );

    final Map<String, dynamic> body = await _get(uri);
    return ActorDetail.fromJson(body);
  }

  /// Fetches the movie credits for a given actor from the TMDb
  /// `/person/{person_id}/movie_credits` endpoint.
  ///
  /// Returns a `List<Movie>` sorted by [Movie.voteAverage] descending
  /// (highest-rated first).
  ///
  /// Throws a subtype of [ApiException] on failure.
  Future<List<Movie>> fetchActorMovies({
    required int personId,
    String language = ApiConfig.defaultLanguage,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/person/$personId/movie_credits')
            .replace(
      queryParameters: {
        'api_key': ApiConfig.apiKey,
        'language': language,
      },
    );

    final Map<String, dynamic> body = await _get(uri);
    return _parseActorMovieList(body);
  }

  // ── Private Helpers (network) ────────────────────────────────────────────

  /// Performs a GET request to [uri] with a timeout and returns the decoded
  /// JSON body as a [Map].
  ///
  /// All potential errors are caught and re-thrown as typed [ApiException]
  /// subclasses so callers never deal with raw platform exceptions.
  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      // Execute the request with a timeout guard.
      final http.Response response = await _client
          .get(uri)
          .timeout(ApiConfig.requestTimeout);

      // ── Success ──
      if (response.statusCode == 200) {
        // Attempt to decode the JSON body.
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        // The server returned 200 but the body is not a JSON object.
        throw const DataParsingException(
          message: 'Expected a JSON object but received a different type.',
        );
      }

      // ── Client / Server Error ──
      throw ServerException(
        message: _httpStatusMessage(response.statusCode),
        statusCode: response.statusCode,
        prefix: response.body,
      );
    } on ApiException {
      // Already a typed exception — just rethrow without wrapping.
      rethrow;
    } on http.ClientException {
      // No internet, DNS resolution failure, or Web CORS failure.
      throw const NetworkException(message: 'Failed to fetch. If on Web, this may be a CORS issue or ad-blocker.');
    } on TimeoutException {
      // The request exceeded [ApiConfig.requestTimeout].
      throw const RequestTimeoutException();
    } on FormatException catch (e) {
      // jsonDecode failed — response was not valid JSON.
      throw DataParsingException(
        message: 'Invalid JSON in response: ${e.message}',
      );
    } catch (e) {
      // Any other unexpected error.
      throw ApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Extracts the `results` array from a TMDb paginated response and
  /// converts each entry into a [Movie].
  List<Movie> _parseMovieList(Map<String, dynamic> body) {
    // TMDb wraps list data inside a top-level `results` key.
    final List<dynamic>? results = body['results'] as List<dynamic>?;

    if (results == null) {
      throw const DataParsingException(
        message: 'Response JSON does not contain a "results" key.',
      );
    }

    // Map each JSON object to a Movie, skipping any entry that fails to
    // parse (defensive — avoids crashing on a single malformed item).
    return results
        .whereType<Map<String, dynamic>>()
        .map((json) => Movie.fromJson(json))
        .toList();
  }

  /// Extracts the `cast` array from a TMDb credits response and converts
  /// each entry into a [Cast]. Results are capped at [maxCast] and sorted
  /// by [Cast.order] (lead actors first).
  List<Cast> _parseCastList(Map<String, dynamic> body, {int maxCast = 20}) {
    final List<dynamic>? castList = body['cast'] as List<dynamic>?;

    if (castList == null) {
      throw const DataParsingException(
        message: 'Response JSON does not contain a "cast" key.',
      );
    }

    final parsed = castList
        .whereType<Map<String, dynamic>>()
        .map((json) => Cast.fromJson(json))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // Limit to the top N cast members.
    return parsed.take(maxCast).toList();
  }

  /// Extracts the `cast` array from a TMDb person movie credits response,
  /// converts each entry into a [Movie], and sorts by [Movie.voteAverage]
  /// descending (highest-rated first).
  List<Movie> _parseActorMovieList(Map<String, dynamic> body) {
    final List<dynamic>? castList = body['cast'] as List<dynamic>?;

    if (castList == null) {
      throw const DataParsingException(
        message: 'Response JSON does not contain a "cast" key.',
      );
    }

    final parsed = castList
        .whereType<Map<String, dynamic>>()
        .map((json) => Movie.fromJson(json))
        .toList()
      ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return parsed;
  }

  /// Returns a user-friendly message for common HTTP status codes.
  String _httpStatusMessage(int code) {
    switch (code) {
      case 401:
        return 'Unauthorized — check your API key.';
      case 403:
        return 'Forbidden — you do not have access to this resource.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests — you are being rate-limited.';
      case 500:
        return 'Internal server error on TMDb.';
      case 503:
        return 'TMDb service is temporarily unavailable.';
      default:
        return 'Request failed with status code $code.';
    }
  }

  /// Releases the underlying HTTP client resources.
  ///
  /// Call this when the service is no longer needed (e.g. in a `dispose()`
  /// method of a provider or a BLoC).
  void dispose() {
    _client.close();
  }
}
