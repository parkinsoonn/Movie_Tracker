// ---------------------------------------------------------------------------
// watched_toggle_button.dart
// ---------------------------------------------------------------------------
// Self-contained reactive toggle button for the "Watched" feature.
//
// Architecture mirrors [WatchlistToggleButton]:
//   1. StreamBuilder listens to `ProfileService.isWatched(movieId)` — a
//      single-document Firestore snapshot listener (minimal reads).
//   2. On tap, `toggleWatched()` writes/deletes the document in Firestore.
//   3. The snapshot fires immediately, updating this button AND the Profile
//      Screen's StreamBuilder simultaneously — no shared state needed.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/movie.dart';
import '../services/profile_service.dart';

/// Visual variant for the watched toggle.
///   • [WatchedButtonStyle.outline] — outline button (detail screen body)
///   • [WatchedButtonStyle.icon] — circular icon (for AppBar / reuse)
enum WatchedButtonStyle { outline, icon }

class WatchedToggleButton extends StatelessWidget {
  final Movie movie;
  final WatchedButtonStyle style;

  /// Service instance — Firestore internally deduplicates snapshot listeners
  /// on the same document path, so creating multiple instances is safe.
  final ProfileService _service = ProfileService();

  WatchedToggleButton({
    super.key,
    required this.movie,
    this.style = WatchedButtonStyle.outline,
  });

  /// Green accent when marked as watched — visually differentiates from the
  /// gold watchlist toggle on the same screen.
  static const Color _watchedColor = Color(0xFF4CAF50);
  static const Color _watchedGlow = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      // Single-document listener: 1 read initially, then change deltas only.
      stream: _service.isWatched(movie.id),
      builder: (context, snapshot) {
        final isWatched = snapshot.data ?? false;

        return style == WatchedButtonStyle.outline
            ? _buildOutlineButton(context, isWatched)
            : _buildIconButton(context, isWatched);
      },
    );
  }

  // ── Outline Button Style (Detail Screen body) ───────────────────────────

  Widget _buildOutlineButton(BuildContext context, bool isWatched) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 56,
      decoration: BoxDecoration(
        // Green fill when watched; white outline when not.
        color: isWatched ? _watchedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
        border: isWatched
            ? null
            : Border.all(color: CinephileTheme.onSurface, width: 1.5),
        boxShadow: isWatched
            ? [
                BoxShadow(
                  color: _watchedGlow.withAlpha(50),
                  blurRadius: 15,
                ),
              ]
            : null,
      ),
      child: TextButton.icon(
        onPressed: () => _service.toggleWatched(movie),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Icon(
            isWatched ? Icons.check_circle : Icons.check,
            key: ValueKey(isWatched),
            color: isWatched ? Colors.white : CinephileTheme.onSurface,
          ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            isWatched ? 'Watched' : 'Mark Watched',
            key: ValueKey(isWatched),
            style: CinephileTheme.headlineMd(
              color: isWatched ? Colors.white : CinephileTheme.onSurface,
            ).copyWith(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ── Icon Style (for AppBar / cards) ─────────────────────────────────────

  Widget _buildIconButton(BuildContext context, bool isWatched) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withAlpha(51),
        border: Border.all(color: Colors.white.withAlpha(26)),
        boxShadow: isWatched
            ? [
                BoxShadow(
                  color: _watchedGlow.withAlpha(50),
                  blurRadius: 15,
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Icon(
            isWatched ? Icons.check_circle : Icons.check_circle_outline,
            key: ValueKey(isWatched),
            color: isWatched ? _watchedColor : CinephileTheme.primary,
          ),
        ),
        onPressed: () => _service.toggleWatched(movie),
      ),
    );
  }
}
