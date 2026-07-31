// ---------------------------------------------------------------------------
// watchlist_toggle_button.dart
// ---------------------------------------------------------------------------
// Self-contained reactive toggle button for the Watchlist feature.
//
// This widget is designed to be dropped into ANY screen (Detail Screen,
// AppBar, movie cards, etc.) without passing state down manually.
//
// How real-time sync works:
//   1. The button uses a StreamBuilder listening to
//      `WatchlistService.isInWatchlist(movieId)` — a single-document
//      Firestore snapshot listener.
//   2. When the user taps the button, `toggleWatchlist()` writes to
//      Firestore.
//   3. The Firestore snapshot fires immediately, updating this button's
//      StreamBuilder AND the Watchlist Screen's StreamBuilder simultaneously.
//   4. No shared state, no event bus, no Provider — just Firestore streams.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/movie.dart';
import '../services/watchlist_service.dart';

/// A reactive watchlist toggle that syncs with Firestore in real-time.
///
/// [style] controls the visual variant:
///   • [WatchlistButtonStyle.elevated] — gold filled CTA (for detail body)
///   • [WatchlistButtonStyle.icon] — circular icon (for AppBar / cards)
enum WatchlistButtonStyle { elevated, icon }

class WatchlistToggleButton extends StatelessWidget {
  final Movie movie;
  final WatchlistButtonStyle style;

  /// Shared service instance — creating multiple instances is fine because
  /// Firestore internally deduplicates snapshot listeners on the same path.
  final WatchlistService _service = WatchlistService();

  WatchlistToggleButton({
    super.key,
    required this.movie,
    this.style = WatchlistButtonStyle.elevated,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      // Listen to this specific movie's presence in the watchlist.
      // Cost: 1 document read initially, then only change events.
      stream: _service.isInWatchlist(movie.id),
      builder: (context, snapshot) {
        final isInWatchlist = snapshot.data ?? false;

        return style == WatchlistButtonStyle.elevated
            ? _buildElevatedButton(context, isInWatchlist)
            : _buildIconButton(context, isInWatchlist);
      },
    );
  }

  // ── Elevated CTA Style ──────────────────────────────────────────────────

  Widget _buildElevatedButton(BuildContext context, bool isInWatchlist) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 56,
      decoration: BoxDecoration(
        // Gold fill when in watchlist; outline when not.
        color: isInWatchlist
            ? CinephileTheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
        border: isInWatchlist
            ? null
            : Border.all(color: CinephileTheme.primaryContainer, width: 1.5),
        boxShadow: isInWatchlist
            ? [
                BoxShadow(
                  color: CinephileTheme.primaryContainer.withAlpha(38),
                  blurRadius: 15,
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: () => _service.toggleWatchlist(movie),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Icon(
            isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
            key: ValueKey(isInWatchlist),
            color: isInWatchlist
                ? CinephileTheme.background
                : CinephileTheme.primaryContainer,
          ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
            key: ValueKey(isInWatchlist),
            style: CinephileTheme.headlineMd(
              color: isInWatchlist
                  ? CinephileTheme.background
                  : CinephileTheme.primaryContainer,
            ).copyWith(fontSize: 16),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  // ── Icon Style (for AppBar) ─────────────────────────────────────────────

  Widget _buildIconButton(BuildContext context, bool isInWatchlist) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withAlpha(51),
        border: Border.all(color: Colors.white.withAlpha(26)),
        boxShadow: isInWatchlist
            ? [
                BoxShadow(
                  color: CinephileTheme.primaryContainer.withAlpha(38),
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
            isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
            key: ValueKey(isInWatchlist),
            color: isInWatchlist
                ? CinephileTheme.primaryContainer
                : CinephileTheme.primary,
          ),
        ),
        onPressed: () => _service.toggleWatchlist(movie),
      ),
    );
  }
}
