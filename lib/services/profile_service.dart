// ---------------------------------------------------------------------------
// profile_service.dart
// ---------------------------------------------------------------------------
// Firebase integration layer for user profile, watched movies, and ratings.
//
// Design decisions:
//   • Streams (not Futures) for movie lists — enables real-time UI updates
//     via StreamBuilder without manual refresh logic.
//   • Subcollections over arrays — each movie is its own document, avoiding
//     the 1 MB Firestore document limit and enabling per-document security
//     rules.
//   • Document IDs = stringified TMDb movieId — guarantees idempotent
//     writes (marking the same movie twice overwrites, not duplicates).
//   • Avatar upload uses Firebase Storage at `avatars/{uid}.jpg`, then
//     updates both Firebase Auth and Firestore for consistency.
// ---------------------------------------------------------------------------

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/watched_movie.dart';
import '../models/rated_movie.dart';
import '../models/movie.dart';

class ProfileService {
  // ── Dependencies ──────────────────────────────────────────────────────────

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  /// Injectable for testing; defaults to live Firebase instances.
  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Shorthand reference to the current user's root document.
  /// Throws [StateError] if called while unauthenticated.
  DocumentReference get _userDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user.');
    return _firestore.collection('users').doc(uid);
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  /// Returns the user's profile document as a real-time stream.
  ///
  /// The document is expected to contain:
  ///   `displayName`, `email`, `photoUrl`, `joinedAt`
  Stream<DocumentSnapshot> getUserProfileStream() {
    return _userDoc.snapshots();
  }

  /// One-shot fetch of the user profile (useful for FutureBuilder in header).
  Future<Map<String, dynamic>> getUserProfile() async {
    final doc = await _userDoc.get();
    return doc.data() as Map<String, dynamic>? ?? {};
  }

  /// Ensures a user document exists in Firestore after sign-up / first login.
  ///
  /// Uses `set` with `merge: true` so it never overwrites existing fields —
  /// safe to call on every app launch.
  Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'Cinephile',
      'email': user.email ?? '',
      'photoUrl': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Profile Update Operations ─────────────────────────────────────────────

  /// Updates the user's display name and/or photo URL in both Firebase Auth
  /// and the Firestore user document atomically.
  ///
  /// Only non-null fields are written, preserving existing values for any
  /// field not explicitly provided.
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user.');

    // Step 1: Update Firebase Auth profile.
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Step 2: Mirror changes to the Firestore user document.
    final Map<String, dynamic> updates = {};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _userDoc.update(updates);
    }
  }

  /// Uploads an avatar image to Firebase Storage and updates the user's
  /// profile photo across both Auth and Firestore.
  ///
  /// Upload flow:
  ///   1. Read the image file from the provided [filePath].
  ///   2. Upload to `avatars/{uid}.jpg` in Firebase Storage.
  ///   3. Retrieve the public download URL.
  ///   4. Call [updateUserProfile] to persist the URL in Auth + Firestore.
  ///
  /// Returns the download URL of the uploaded avatar.
  Future<String> uploadAvatar(String filePath) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user.');

    // Storage path: avatars/{uid}.jpg — one avatar per user, overwrites old.
    final ref = _storage.ref().child('avatars/${user.uid}.jpg');

    // Upload the file with JPEG content type for proper CDN serving.
    await ref.putFile(
      File(filePath),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Get the public download URL from Firebase Storage.
    final downloadUrl = await ref.getDownloadURL();

    // Persist the URL in both Firebase Auth and Firestore.
    await updateUserProfile(photoUrl: downloadUrl);

    return downloadUrl;
  }

  // ── Watched Movies ────────────────────────────────────────────────────────

  /// Real-time stream of the user's watched movies, ordered by most recently
  /// added first.
  Stream<List<WatchedMovie>> getWatchedMoviesStream() {
    return _userDoc
        .collection('watched_movies')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WatchedMovie.fromFirestore(doc))
            .toList());
  }

  /// Adds a movie to the user's watched list.
  ///
  /// Uses the movieId as the document ID for idempotent upserts.
  Future<void> addWatchedMovie(WatchedMovie movie) async {
    await _userDoc
        .collection('watched_movies')
        .doc(movie.movieId.toString())
        .set(movie.toMap());
  }

  /// Removes a movie from the watched list.
  Future<void> removeWatchedMovie(int movieId) async {
    await _userDoc
        .collection('watched_movies')
        .doc(movieId.toString())
        .delete();
  }

  // ── Rated Movies ──────────────────────────────────────────────────────────

  /// Real-time stream of the user's rated movies, ordered by most recently
  /// rated first.
  Stream<List<RatedMovie>> getRatedMoviesStream() {
    return _userDoc
        .collection('rated_movies')
        .orderBy('ratedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatedMovie.fromFirestore(doc))
            .toList());
  }

  /// Adds or updates a movie rating.
  Future<void> addRatedMovie(RatedMovie movie) async {
    await _userDoc
        .collection('rated_movies')
        .doc(movie.movieId.toString())
        .set(movie.toMap());
  }

  /// Removes a rating from the user's list.
  Future<void> removeRatedMovie(int movieId) async {
    await _userDoc
        .collection('rated_movies')
        .doc(movieId.toString())
        .delete();
  }

  // ── Single-Document Listeners (for Detail Screen widgets) ────────────────

  /// Lightweight single-document listener that emits `true` when the given
  /// movie is in the watched list, `false` otherwise.
  ///
  /// Cost: 1 document read initially, then only change-event deltas.
  /// Mirrors [WatchlistService.isInWatchlist] for consistency.
  Stream<bool> isWatched(int movieId) {
    return _userDoc
        .collection('watched_movies')
        .doc(movieId.toString())
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Atomic toggle: marks a movie as watched if not yet, removes it if
  /// already watched. Both the Profile Screen (via `getWatchedMoviesStream`)
  /// and the Detail Screen toggle (via `isWatched`) update instantly because
  /// they listen to Firestore snapshots on the same collection/document.
  Future<void> toggleWatched(Movie movie) async {
    final docRef =
        _userDoc.collection('watched_movies').doc(movie.id.toString());
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      final watched = WatchedMovie(
        movieId: movie.id,
        title: movie.title,
        posterPath: movie.posterPath,
        addedAt: DateTime.now(),
      );
      await docRef.set(watched.toMap());
    }
  }

  /// Single-document listener that emits the user's rating for one movie,
  /// or `null` if the movie has not been rated.
  ///
  /// Used by [RatingSection] on the Detail Screen to show the current
  /// rating and react to changes in real-time.
  Stream<double?> getRatingStream(int movieId) {
    return _userDoc
        .collection('rated_movies')
        .doc(movieId.toString())
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      return (data['rating'] as num?)?.toDouble();
    });
  }
}

