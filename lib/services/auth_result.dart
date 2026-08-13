// ---------------------------------------------------------------------------
// auth_result.dart
// ---------------------------------------------------------------------------
// A lightweight result wrapper for authentication operations.
//
// Instead of throwing exceptions up to the UI layer (which forces every
// caller to write try-catch), AuthService returns an AuthResult that
// carries either the successful User or a user-friendly error message.
// ---------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';

/// Encapsulates the outcome of an authentication operation.
///
/// Check [isSuccess] before accessing [user]. If the operation failed,
/// [errorMessage] contains a user-facing string ready for display.
///
/// ```dart
/// final result = await authService.signIn(email, password);
/// if (result.isSuccess) {
///   // Navigate to home
/// } else {
///   showSnackBar(result.errorMessage!);
/// }
/// ```
class AuthResult {
  /// The authenticated Firebase user. Non-null only on success.
  final User? user;

  /// A user-friendly error description. Non-null only on failure.
  final String? errorMessage;

  // ── Named constructors ──────────────────────────────────────────────────

  /// Creates a successful result containing the authenticated [user].
  const AuthResult.success(User this.user) : errorMessage = null;

  /// Creates a failed result containing a human-readable [errorMessage].
  const AuthResult.failure(String this.errorMessage) : user = null;

  // ── Convenience getters ─────────────────────────────────────────────────

  /// `true` when the operation completed successfully and [user] is available.
  bool get isSuccess => user != null;

  /// `true` when the operation failed and [errorMessage] is available.
  bool get isFailure => !isSuccess;

  @override
  String toString() => isSuccess
      ? 'AuthResult.success(uid: ${user!.uid})'
      : 'AuthResult.failure($errorMessage)';
}
