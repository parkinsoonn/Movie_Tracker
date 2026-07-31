// ---------------------------------------------------------------------------
// auth_exception.dart
// ---------------------------------------------------------------------------
// Custom exception class for Firebase Authentication errors.
//
// Wraps FirebaseAuthException error codes into user-friendly English
// messages so the UI layer never needs to interpret raw Firebase codes.
// ---------------------------------------------------------------------------

/// A typed exception for authentication-related failures.
///
/// Carries a user-facing [message] suitable for displaying in a SnackBar
/// or dialog, plus the original Firebase [code] for logging/debugging.
class AuthException implements Exception {
  /// A human-readable, user-friendly description of the error.
  final String message;

  /// The raw Firebase error code (e.g. `user-not-found`, `wrong-password`).
  final String? code;

  const AuthException({
    required this.message,
    this.code,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AuthException: $message');
    if (code != null) buffer.write(' [code: $code]');
    return buffer.toString();
  }

  // ── Factory: map Firebase error codes to friendly messages ────────────────

  /// Creates an [AuthException] from a Firebase `code` string.
  ///
  /// Covers every commonly encountered [FirebaseAuthException] code.
  /// Unknown codes fall through to a generic message so the app never
  /// shows a raw internal string to the user.
  factory AuthException.fromCode(String code) {
    final String message;

    switch (code) {
      // ── Sign-up errors ──────────────────────────────────────────────────
      case 'email-already-in-use':
        message = 'An account with this email address already exists. '
            'Please sign in or use a different email.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid. '
            'Please check the format and try again.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password sign-up is currently disabled. '
            'Please contact support.';
        break;
      case 'weak-password':
        message = 'Your password is too weak. '
            'Please use at least 6 characters with a mix of letters and numbers.';
        break;

      // ── Sign-in errors ──────────────────────────────────────────────────
      case 'user-not-found':
        message = 'No account found with this email address. '
            'Please check your email or create a new account.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. '
            'Please try again or reset your password.';
        break;
      case 'invalid-credential':
        message = 'The email or password is incorrect. '
            'Please double-check your credentials and try again.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. '
            'Please contact support for assistance.';
        break;

      // ── Rate-limiting / abuse ───────────────────────────────────────────
      case 'too-many-requests':
        message = 'Too many unsuccessful attempts. '
            'Please wait a few minutes before trying again.';
        break;

      // ── Network / infrastructure ────────────────────────────────────────
      case 'network-request-failed':
        message = 'A network error occurred. '
            'Please check your internet connection and try again.';
        break;

      // ── Catch-all ───────────────────────────────────────────────────────
      default:
        message = 'An unexpected authentication error occurred. '
            'Please try again later.';
        break;
    }

    return AuthException(message: message, code: code);
  }
}
