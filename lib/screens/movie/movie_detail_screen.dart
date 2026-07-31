// ---------------------------------------------------------------------------
// movie_detail_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir movie detail screen — pixel-matched to the Stitch design.
//
// Features:
//   • Hero backdrop image with gradient fade
//   • Centered poster thumbnail with gold glow
//   • Display-large movie title
//   • Year • Runtime • Genre chips
//   • Gold star rating (large format)
//   • "Add to Watchlist" (gold CTA) + "Watched" (outline) buttons
//   • Storyline section
//   • Horizontal scrollable cast list
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/movie.dart';
import '../../widgets/watchlist_toggle_button.dart';
import '../../widgets/watched_toggle_button.dart';
import '../../widgets/rating_section.dart';
import '../../widgets/cast_list.dart';
import '../../widgets/movie_comments.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.fullPosterUrl;
    final backdropUrl = movie.fullBackdropUrl ?? posterUrl;
    final year = movie.releaseDate != null && movie.releaseDate!.length >= 4
        ? movie.releaseDate!.substring(0, 4)
        : '';

    return Scaffold(
      backgroundColor: CinephileTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Backdrop + Navigation ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: CinephileTheme.background,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withAlpha(51),
                    border: Border.all(color: Colors.white.withAlpha(26)),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: CinephileTheme.onSurface,
                    size: 22,
                  ),
                ),
              ),
            ),
            actions: [
              // Reactive watchlist icon — syncs with Firestore in real-time.
              // Uses the same stream as the body CTA button below.
              Padding(
                padding: const EdgeInsets.all(8),
                child: WatchlistToggleButton(
                  movie: movie,
                  style: WatchlistButtonStyle.icon,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop image
                  if (backdropUrl != null)
                    Image.network(
                      backdropUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withAlpha(102),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, e, s) =>
                          Container(color: CinephileTheme.background),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CinephileTheme.brandPurple,
                            CinephileTheme.background,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          CinephileTheme.background.withAlpha(204),
                          CinephileTheme.background,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Centered poster thumbnail
                  if (posterUrl != null)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 140,
                          height: 210,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              CinephileTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: Colors.white.withAlpha(26),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CinephileTheme.primaryContainer
                                    .withAlpha(26),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => Container(
                              color: CinephileTheme.surfaceContainerHigh,
                              child: const Icon(
                                Icons.movie_outlined,
                                color: CinephileTheme.onSurfaceVariant,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Movie Details ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    movie.title,
                    style: CinephileTheme.displayLg(
                      color: CinephileTheme.onSurface,
                    ).copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: CinephileTheme.spacingBase),

                  // Year + Genre chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        year,
                        style: CinephileTheme.labelMd(
                          color: CinephileTheme.onSurfaceVariant,
                        ),
                      ),
                      _dot(),
                      Text(
                        '2h 30m',
                        style: CinephileTheme.labelMd(
                          color: CinephileTheme.onSurfaceVariant,
                        ),
                      ),
                      _dot(),
                      _genreChip('Sci-Fi'),
                      _genreChip('Adventure'),
                    ],
                  ),

                  const SizedBox(height: CinephileTheme.spacingStackSm),

                  // Rating
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: CinephileTheme.primaryContainer
                                  .withAlpha(38),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          color: CinephileTheme.primaryContainer,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: CinephileTheme.headlineLg(
                                  color: CinephileTheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/10',
                                style: CinephileTheme.bodyMd(
                                  color: CinephileTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_formatVoteCount(movie.voteCount)} votes',
                            style: CinephileTheme.labelSm(
                              color: CinephileTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: CinephileTheme.spacingStackLg),

                  // Action buttons
                  Row(
                    children: [
                      // Reactive watchlist CTA — StreamBuilder inside
                      // listens to Firestore and updates the label/color
                      // instantly when toggled here OR from the Watchlist
                      // Screen (both share the same Firestore path).
                      Expanded(
                        child: WatchlistToggleButton(
                          movie: movie,
                          style: WatchlistButtonStyle.elevated,
                        ),
                      ),
                      const SizedBox(width: CinephileTheme.spacingStackSm),

                      // Reactive watched toggle — StreamBuilder inside
                      // listens to Firestore and updates the visual state
                      // instantly. Shares the same collection path as the
                      // Profile Screen's watched-movies stream.
                      WatchedToggleButton(
                        movie: movie,
                        style: WatchedButtonStyle.outline,
                      ),
                    ],
                  ),

                  const SizedBox(height: CinephileTheme.spacingStackLg),

                  // ── Your Rating ─────────────────────────────────────────
                  // Interactive star-rating section. StreamBuilder listens
                  // to the user's rating for this specific movie in
                  // Firestore (single-document snapshot). Changes here
                  // propagate instantly to the Profile Screen's rated-movies
                  // tab and statistics row via shared Firestore listeners.
                  RatingSection(movie: movie),

                  const SizedBox(height: CinephileTheme.spacingStackLg),

                  // Storyline
                  Text(
                    'Storyline',
                    style: CinephileTheme.headlineLg(
                      color: CinephileTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: CinephileTheme.spacingStackSm),
                  Text(
                    movie.overview.isNotEmpty
                        ? movie.overview
                        : 'No storyline available for this movie.',
                    style: CinephileTheme.bodyLg(
                      color: CinephileTheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: CinephileTheme.spacingStackLg),

                  // Cast section
                  Text(
                    'Cast',
                    style: CinephileTheme.headlineLg(
                      color: CinephileTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: CinephileTheme.spacingStackSm),
                ],
              ),
            ),
          ),

          // ── Cast Horizontal List ───────────────────────────────────────────
          // Fetches real cast data from TMDb and displays with shimmer
          // loading, error handling, and placeholder support.
          SliverToBoxAdapter(
            child: CastList(movieId: movie.id),
          ),

          // ── Divider ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
                vertical: CinephileTheme.spacingStackSm,
              ),
              child: Divider(
                color: Colors.white.withAlpha(15),
                height: 1,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: CinephileTheme.spacingStackSm),
          ),

          // ── Comments / Reviews Section ─────────────────────────────────────
          SliverToBoxAdapter(
            child: MovieComments(movieId: movie.id),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: CinephileTheme.spacingStackLg),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _dot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CinephileTheme.onSurfaceVariant.withAlpha(128),
      ),
    );
  }

  Widget _genreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(26)),
        color: Colors.white.withAlpha(13),
      ),
      child: Text(
        label,
        style: CinephileTheme.labelMd(color: CinephileTheme.onSurface),
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}