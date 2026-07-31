// ---------------------------------------------------------------------------
// rating_section.dart
// ---------------------------------------------------------------------------
// Interactive star-rating component with real-time Firestore sync.
//
// Architecture:
//   • StreamBuilder listens to `ProfileService.getRatingStream(movieId)` —
//     a single-document Firestore snapshot (minimal reads).
//   • Each of the 5 stars represents 2 points on a 1–10 scale.
//   • Half-star precision is achieved by splitting each star's hit area into
//     left/right halves via `GestureDetector` + `localPosition`.
//   • On tap → writes/updates via `ProfileService.addRatedMovie()`.
//   • Long-press on a rated star → removes the rating entirely.
//   • The Profile Screen's rated-movies StreamBuilder and stats row update
//     instantly because they listen to the same Firestore collection.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/movie.dart';
import '../models/rated_movie.dart';
import '../services/profile_service.dart';

class RatingSection extends StatelessWidget {
  final Movie movie;

  /// Service instance — Firestore deduplicates listeners on the same path.
  final ProfileService _service = ProfileService();

  RatingSection({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double?>(
      // Single-document listener for this movie's rating.
      // Emits null when unrated, or the 0.0–10.0 rating value.
      stream: _service.getRatingStream(movie.id),
      builder: (context, snapshot) {
        final currentRating = snapshot.data;

        return _RatingSectionContent(
          movie: movie,
          currentRating: currentRating,
          service: _service,
        );
      },
    );
  }
}

/// Stateful inner widget that handles the interactive star rendering and
/// hover/drag feedback. Separated from the outer StreamBuilder to keep
/// animation state local (avoids rebuilding the entire tree on stream events).
class _RatingSectionContent extends StatefulWidget {
  final Movie movie;
  final double? currentRating;
  final ProfileService service;

  const _RatingSectionContent({
    required this.movie,
    required this.currentRating,
    required this.service,
  });

  @override
  State<_RatingSectionContent> createState() => _RatingSectionContentState();
}

class _RatingSectionContentState extends State<_RatingSectionContent>
    with SingleTickerProviderStateMixin {
  /// Transient preview rating shown while the user is interacting.
  double? _previewRating;

  /// Animation controller for the pulse effect on rating change.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// The rating value to render (preview takes priority over persisted).
  double get _displayRating => _previewRating ?? widget.currentRating ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final isRated = widget.currentRating != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CinephileTheme.surfaceContainerHigh.withAlpha(180),
        borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        border: Border.all(
          color: isRated
              ? CinephileTheme.primaryContainer.withAlpha(60)
              : CinephileTheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────────────────────
          Row(
            children: [
              Icon(
                isRated ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 20,
                color: CinephileTheme.primaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Rating',
                style: CinephileTheme.headlineMd(
                  color: CinephileTheme.onSurface,
                ).copyWith(fontSize: 16),
              ),
              const Spacer(),
              // Rating value badge (visible when rated)
              if (isRated)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CinephileTheme.primaryContainer.withAlpha(25),
                    borderRadius:
                        BorderRadius.circular(CinephileTheme.radiusMd),
                    border: Border.all(
                      color: CinephileTheme.primaryContainer.withAlpha(60),
                    ),
                  ),
                  child: Text(
                    '${widget.currentRating!.toStringAsFixed(1)} / 10',
                    style: CinephileTheme.labelMd(
                      color: CinephileTheme.primaryContainer,
                    ).copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Interactive star row ──────────────────────────────────────
          Center(
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) => _buildStar(index)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Helper text ──────────────────────────────────────────────
          Center(
            child: Text(
              isRated
                  ? 'Tap to change • Long-press to remove'
                  : 'Tap a star to rate this movie',
              style: CinephileTheme.labelSm(
                color: CinephileTheme.onSurfaceVariant,
              ).copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single interactive star with half-star precision.
  ///
  /// Each star spans 2 rating points:
  ///   - Left half tap  → (index * 2) + 1 (e.g. star 0 left = 1)
  ///   - Right half tap → (index * 2) + 2 (e.g. star 0 right = 2)
  Widget _buildStar(int index) {
    final fullThreshold = (index + 1) * 2.0;
    final halfThreshold = (index * 2) + 1.0;

    // Determine fill state based on the display rating.
    final double fillFraction;
    if (_displayRating >= fullThreshold) {
      fillFraction = 1.0;
    } else if (_displayRating >= halfThreshold) {
      fillFraction = 0.5;
    } else {
      fillFraction = 0.0;
    }

    return GestureDetector(
      onTapDown: (details) {
        // Determine which half of the star was tapped.
        final starWidth = 44.0; // matches the SizedBox width below
        final isLeftHalf = details.localPosition.dx < starWidth / 2;
        final tappedRating = isLeftHalf
            ? (index * 2) + 1.0
            : (index * 2) + 2.0;

        _submitRating(tappedRating);
      },
      onLongPress: () {
        // Long-press removes the rating entirely.
        if (widget.currentRating != null) {
          _removeRating();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            children: [
              // Background (empty) star
              Icon(
                Icons.star_rounded,
                size: 44,
                color: CinephileTheme.surfaceContainer,
              ),
              // Filled portion — clipped to show half or full
              ClipRect(
                clipper: _StarClipper(fillFraction),
                child: Icon(
                  Icons.star_rounded,
                  size: 44,
                  color: CinephileTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Writes the rating to Firestore and triggers the pulse animation.
  void _submitRating(double rating) {
    // If tapping the same rating, treat it as a removal.
    if (widget.currentRating == rating) {
      _removeRating();
      return;
    }

    // Optimistic preview for instant feedback.
    setState(() => _previewRating = rating);

    // Pulse animation
    _pulseController.forward().then((_) => _pulseController.reverse());

    // Persist to Firestore — the StreamBuilder will update on confirmation.
    final rated = RatedMovie(
      movieId: widget.movie.id,
      title: widget.movie.title,
      posterPath: widget.movie.posterPath,
      rating: rating,
      ratedAt: DateTime.now(),
    );
    widget.service.addRatedMovie(rated).then((_) {
      // Clear preview once Firestore confirms (stream takes over).
      if (mounted) setState(() => _previewRating = null);
    });
  }

  /// Removes the rating from Firestore.
  void _removeRating() {
    setState(() => _previewRating = null);
    widget.service.removeRatedMovie(widget.movie.id);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAR CLIPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Custom clipper that reveals a fraction (0.0, 0.5, or 1.0) of the star icon
/// from left to right — used to render half-star states.
class _StarClipper extends CustomClipper<Rect> {
  final double fraction;

  const _StarClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) => fraction != oldClipper.fraction;
}
