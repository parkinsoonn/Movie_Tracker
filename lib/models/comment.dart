// ---------------------------------------------------------------------------
// comment.dart
// ---------------------------------------------------------------------------
// Data model for a user comment (review) on a movie.
//
// Stored in `movies/{movieId}/comments/{commentId}`. Each document contains
// the author's UID, display name, comment text, and creation timestamp.
//
// Subcollection design:
//   • Co-locates comments with the movie they belong to → single query, no
//     composite index required.
//   • Each comment is its own document → avoids the 1 MB Firestore document
//     limit even for blockbuster movies with thousands of reviews.
//   • Auto-generated document IDs → allows multiple comments per user.
// ---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  /// Firestore document ID (auto-generated).
  final String id;

  /// TMDb movie identifier this comment belongs to.
  final int movieId;

  /// Firebase Auth UID of the comment author.
  final String userId;

  /// Display name of the author at the time of posting.
  final String userName;

  /// The comment body text.
  final String text;

  /// The user's rating for the movie at the time of commenting (optional).
  final double? rating;

  /// When this comment was created.
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.userName,
    required this.text,
    this.rating,
    required this.createdAt,
  });

  // ── Firestore Serialization ───────────────────────────────────────────────

  /// Creates a [Comment] from a Firestore document snapshot.
  ///
  /// Falls back to sensible defaults for missing fields so the app never
  /// crashes on incomplete data.
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Comment(
      id: doc.id,
      movieId: (data['movieId'] as num?)?.toInt() ?? 0,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? 'Anonymous',
      text: (data['text'] as String?) ?? '',
      rating: (data['rating'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this model to a Firestore-compatible map for writes.
  ///
  /// Uses [FieldValue.serverTimestamp] for `createdAt` to guarantee
  /// consistent ordering regardless of client clock drift.
  Map<String, dynamic> toMap() => {
        'movieId': movieId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      };

  // ── Convenience ───────────────────────────────────────────────────────────

  /// Returns the rating formatted as "8.5".
  String get formattedRating => rating?.toStringAsFixed(1) ?? '';

  /// Returns a formatted date string (e.g. "12 Jul 2026").
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  /// Returns a human-readable relative time string (e.g. "2 hours ago").
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w week${w == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return '$mo month${mo == 1 ? '' : 's'} ago';
    }
    final y = (diff.inDays / 365).floor();
    return '$y year${y == 1 ? '' : 's'} ago';
  }
}
