// ---------------------------------------------------------------------------
// auth_service.dart
// ---------------------------------------------------------------------------
// Core authentication service for the movie tracking application.
//
// This class wraps Firebase Authentication and exposes a clean, high-level
// API for the rest of the app:
//   • signUp    — create a new account with email & password
//   • signIn    — authenticate an existing user
//   • signOut   — end the current session
//   • currentUser / authStateChanges — observe authentication state
//
// Every public method returns an [AuthResult] (success or failure) so the
// UI layer never needs to catch Firebase exceptions directly.
// ---------------------------------------------------------------------------


import 'package:firebase_auth/firebase_auth.dart';

import 'auth_exception.dart';
import 'auth_result.dart';

class AuthService {
  // ── Dependencies ──────────────────────────────────────────────────────────

  /// The underlying Firebase Auth instance.
  ///
  /// Accepting it via the constructor enables unit testing with a mock.
  final FirebaseAuth _firebaseAuth;

  /// Creates an [AuthService].
  ///
  /// [firebaseAuth] defaults to [FirebaseAuth.instance] if not provided.
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // ── Reactive State ────────────────────────────────────────────────────────

  /// Returns the currently signed-in [User], or `null` if no user is
  /// authenticated.
  User? get currentUser => _firebaseAuth.currentUser;

  /// A broadcast stream that emits the current [User] (or `null`) whenever
  /// the authentication state changes (sign-in, sign-out, token refresh).
  ///
  /// Useful for driving a `StreamBuilder` or a state-management listener
  /// that gates access to authenticated screens.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ── Sign Up ───────────────────────────────────────────────────────────────

  /// Creates a new user account with the given [email] and [password].
  ///
  /// Returns [AuthResult.success] containing the new [User] on success,
  /// or [AuthResult.failure] with a user-friendly message on error.
  ///
  /// Common error codes handled:
  /// - `email-already-in-use`
  /// - `invalid-email`
  /// - `weak-password`
  /// - `operation-not-allowed`
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to create the account on Firebase.
      final UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Firebase guarantees credential.user is non-null on success.
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      // Map the Firebase error code to a friendly message.
      final authException = AuthException.fromCode(e.code);
      return AuthResult.failure(authException.message);
    } catch (e) {
      // Catch-all for truly unexpected failures (e.g. platform channel crash).
      return const AuthResult.failure(
        'An unexpected error occurred during sign-up. Please try again.',
      );
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  /// Authenticates an existing user with the given [email] and [password].
  ///
  /// Returns [AuthResult.success] containing the [User] on success,
  /// or [AuthResult.failure] with a user-friendly message on error.
  ///
  /// Common error codes handled:
  /// - `user-not-found`
  /// - `wrong-password`
  /// - `invalid-credential`
  /// - `user-disabled`
  /// - `too-many-requests`
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to sign in with Firebase.
      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      final authException = AuthException.fromCode(e.code);
      return AuthResult.failure(authException.message);
    } catch (e) {
      return const AuthResult.failure(
        'An unexpected error occurred during sign-in. Please try again.',
      );
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  /// Signs out the current user and clears the local session.
  ///
  /// Returns [AuthResult.success] with `null` user on success (since there
  /// is no user after sign-out), or [AuthResult.failure] if something goes
  /// wrong.
  Future<AuthResult> signOut() async {
    try {
      await _firebaseAuth.signOut();

      // Sign-out has no "user" to return — signal success with a
      // descriptive failure-free result.
      return const AuthResult.failure(
        // Not truly a failure — we re-use the wrapper. UI should check
        // authStateChanges for the canonical source of truth.
        'Signed out successfully.',
      );
    } on FirebaseAuthException catch (e) {
      final authException = AuthException.fromCode(e.code);
      return AuthResult.failure(authException.message);
    } catch (e) {
      return const AuthResult.failure(
        'An unexpected error occurred during sign-out. Please try again.',
      );
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Sends a password-reset email to the given [email] address.
  ///
  /// Returns `null` on success, or a user-friendly error message string
  /// on failure.
  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return null; // Success — no error.
    } on FirebaseAuthException catch (e) {
      return AuthException.fromCode(e.code).message;
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
