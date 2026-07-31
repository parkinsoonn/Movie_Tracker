// ---------------------------------------------------------------------------
// api_exception.dart
// ---------------------------------------------------------------------------
// Custom exception hierarchy for TMDb API errors.
//
// Using dedicated exception types instead of generic [Exception] lets
// calling code distinguish between network failures, server errors,
// unexpected payloads, and timeouts — and react accordingly.
// ---------------------------------------------------------------------------

/// Base exception class for all API-related errors.
///
/// Every API error carries a human-readable [message], an optional HTTP
/// [statusCode], and an optional raw [prefix] (e.g. the response body) that
/// can be logged for debugging.
class ApiException implements Exception {
  /// A short, human-readable description of what went wrong.
  final String message;

  /// The HTTP status code returned by the server, if available.
  final int? statusCode;

  /// Optional raw detail payload (e.g. the response body) for debugging.
  final String? prefix;

  const ApiException({
    required this.message,
    this.statusCode,
    this.prefix,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) buffer.write(' (HTTP $statusCode)');
    if (prefix != null && prefix!.isNotEmpty) buffer.write(' — $prefix');
    return buffer.toString();
  }
}

// ── Specialised sub-types ───────────────────────────────────────────────────

/// Thrown when the device has no internet connection or the request
/// could not reach the server at all (DNS failure, socket error, etc.).
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'No internet connection or the server is unreachable.',
    super.statusCode,
    super.prefix,
  });
}

/// Thrown when the server responds with an error status code (4xx / 5xx).
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    required super.statusCode,
    super.prefix,
  });
}

/// Thrown when the response body cannot be parsed as expected JSON or
/// when required fields are missing from the payload.
class DataParsingException extends ApiException {
  const DataParsingException({
    super.message = 'Failed to parse the API response.',
    super.statusCode,
    super.prefix,
  });
}

/// Thrown when a request exceeds the configured timeout duration.
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException({
    super.message = 'The request timed out. Please try again later.',
    super.statusCode,
    super.prefix,
  });
}
