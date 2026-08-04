// ---------------------------------------------------------------------------
// movie_comments.dart
// ---------------------------------------------------------------------------
// Self-contained widget that displays and manages comments for a movie.
//
// Features:
//   • Real-time comment list via Firestore StreamBuilder
//   • Cinematic Noir themed comment cards with avatar, name, time, text
//   • Inline text field + send button for adding comments
//   • Empty state illustration encouraging the first review
//   • Delete own comments via long-press
//   • Error and loading states
// ---------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

class MovieComments extends StatefulWidget {
  /// TMDb movie ID whose comments to display.
  final int movieId;

  const MovieComments({super.key, required this.movieId});

  @override
  State<MovieComments> createState() => _MovieCommentsState();
}

class _MovieCommentsState extends State<MovieComments> {
  final CommentService _commentService = CommentService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Submit Comment ──────────────────────────────────────────────────────

  Future<void> _submitComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _commentService.addComment(
        movieId: widget.movieId,
        text: text,
      );
      _textController.clear();
      _focusNode.unfocus();
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: CinephileTheme.surfaceContainerHigh,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment. Please try again.'),
            backgroundColor: CinephileTheme.surfaceContainerHigh,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Delete Comment ──────────────────────────────────────────────────────

  Future<void> _deleteComment(Comment comment) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != comment.userId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinephileTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        ),
        title: Text(
          'Delete Comment',
          style: CinephileTheme.headlineMd(color: CinephileTheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: CinephileTheme.bodyMd(color: CinephileTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: CinephileTheme.labelMd(color: CinephileTheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: CinephileTheme.labelMd(color: CinephileTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _commentService.deleteComment(
          movieId: widget.movieId,
          commentId: comment.id,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete comment.'),
              backgroundColor: CinephileTheme.surfaceContainerHigh,
            ),
          );
        }
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CinephileTheme.spacingContainerPadding,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: CinephileTheme.primaryContainer,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Reviews',
                style: CinephileTheme.headlineLg(
                  color: CinephileTheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: CinephileTheme.spacingStackSm),

        // ── Comment Input ──────────────────────────────────────────────
        _buildCommentInput(),

        const SizedBox(height: CinephileTheme.spacingStackSm),

        // ── Comments List ──────────────────────────────────────────────
        StreamBuilder<List<Comment>>(
          stream: _commentService.commentsStream(widget.movieId),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: CinephileTheme.primaryContainer,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            // Error
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CinephileTheme.spacingContainerPadding,
                  vertical: 24,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CinephileTheme.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
                    border: Border.all(
                      color: CinephileTheme.error.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: CinephileTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Could not load reviews.',
                          style: CinephileTheme.bodyMd(
                            color: CinephileTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final comments = snapshot.data ?? [];

            // Empty state
            if (comments.isEmpty) {
              return _buildEmptyState();
            }

            // Comments list
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
              ),
              child: Column(
                children: comments.map((comment) {
                  return _buildCommentCard(comment);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Comment Input Widget ──────────────────────────────────────────────────

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CinephileTheme.spacingContainerPadding,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: CinephileTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(CinephileTheme.radiusXxl),
          border: Border.all(
            color: CinephileTheme.outlineVariant.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: CinephileTheme.ctaGradientDiagonal,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text field
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: CinephileTheme.bodyMd(
                  color: CinephileTheme.onSurface,
                ),
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a review…',
                  hintStyle: CinephileTheme.bodyMd(
                    color: CinephileTheme.onSurfaceVariant.withAlpha(120),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: _isSending ? null : _submitComment,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CinephileTheme.ctaGradient,
                  boxShadow: [
                    BoxShadow(
                      color: CinephileTheme.primaryContainer.withAlpha(40),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State Widget ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CinephileTheme.spacingContainerPadding,
        vertical: 24,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: CinephileTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
          border: Border.all(
            color: Colors.white.withAlpha(10),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CinephileTheme.primaryContainer.withAlpha(15),
                border: Border.all(
                  color: CinephileTheme.primaryContainer.withAlpha(40),
                ),
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: CinephileTheme.primaryContainer,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: CinephileTheme.headlineMd(
                color: CinephileTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts\nabout this movie!',
              textAlign: TextAlign.center,
              style: CinephileTheme.bodyMd(
                color: CinephileTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Comment Card Widget ───────────────────────────────────────────────────

  Widget _buildCommentCard(Comment comment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwn = currentUser != null && currentUser.uid == comment.userId;

    // Generate a deterministic color from the user ID for the avatar.
    final avatarColorIndex = comment.userId.hashCode % _avatarColors.length;
    final avatarColor = _avatarColors[avatarColorIndex.abs()];

    return GestureDetector(
      onLongPress: isOwn ? () => _deleteComment(comment) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CinephileTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
          border: Border.all(
            color: isOwn
                ? CinephileTheme.primaryContainer.withAlpha(30)
                : Colors.white.withAlpha(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Avatar + Name ──────────────────────────────────
            Row(
              children: [
                // Colored avatar circle with initial
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColor.withAlpha(40),
                    border: Border.all(
                      color: avatarColor.withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      comment.userName.isNotEmpty
                          ? comment.userName[0].toUpperCase()
                          : '?',
                      style: CinephileTheme.labelMd(
                        color: avatarColor,
                      ).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CinephileTheme.labelMd(
                            color: CinephileTheme.onSurface,
                          ).copyWith(fontSize: 13),
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CinephileTheme.primaryContainer.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'You',
                            style: CinephileTheme.labelSm(
                              color: CinephileTheme.primaryContainer,
                            ).copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Delete icon for own comments
                if (isOwn)
                  GestureDetector(
                    onTap: () => _deleteComment(comment),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: CinephileTheme.onSurfaceVariant.withAlpha(120),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Comment Text ─────────────────────────────────────────
            Text(
              comment.text,
              style: CinephileTheme.bodyMd(
                color: CinephileTheme.onSurface,
              ).copyWith(height: 1.5),
            ),

            const SizedBox(height: 12),

            // ── Footer: Rating + Date ────────────────────────────────
            Row(
              children: [
                if (comment.rating != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: CinephileTheme.starColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comment.formattedRating,
                        style: CinephileTheme.labelSm(
                          color: CinephileTheme.starColor,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  comment.formattedDate,
                  style: CinephileTheme.labelSm(
                    color: CinephileTheme.onSurfaceVariant,
                  ).copyWith(fontSize: 10, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar Color Palette ──────────────────────────────────────────────────

  static const List<Color> _avatarColors = [
    Color(0xFF8A2BE2), // purple
    Color(0xFFFF6B6B), // coral
    Color(0xFF4ECDC4), // teal
    Color(0xFFFFD93D), // gold
    Color(0xFF6C5CE7), // indigo
    Color(0xFFA8E6CF), // mint
    Color(0xFFFF8A5B), // orange
    Color(0xFF81ECEC), // cyan
    Color(0xFFFD79A8), // pink
    Color(0xFF55EFC4), // green
  ];
}
