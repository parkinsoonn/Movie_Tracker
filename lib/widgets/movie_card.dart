// ---------------------------------------------------------------------------
// movie_card.dart
// ---------------------------------------------------------------------------
// Reusable MovieCard widget matching the Stitch "Cinematic Noir" design.
//
// Features:
//   • 2:3 aspect-ratio poster with gradient overlay
//   • Gold star rating badge on the poster
//   • Film title + release year below in monospace label font
//   • Hover/tap scale animation
//   • Navigates to MovieDetailScreen on tap
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/movie.dart';
import '../screens/movie/movie_detail_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final imageUrl = movie.fullPosterUrl;
    final year = movie.releaseDate != null && movie.releaseDate!.length >= 4
        ? movie.releaseDate!.substring(0, 4)
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: CinephileTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
          border: Border.all(
            color: Colors.white.withAlpha(13), // ~5% opacity
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster Area ──────────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Poster image
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => _posterPlaceholder(),
                    )
                  else
                    _posterPlaceholder(),

                  // Gradient overlay (bottom fade for rating legibility)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            CinephileTheme.background.withAlpha(
                              (0.9 * 255).toInt(),
                            ),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Gold star rating badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: CinephileTheme.starColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: CinephileTheme.labelSm(
                            color: CinephileTheme.starColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Metadata Area ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CinephileTheme.labelMd(
                      color: CinephileTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    year,
                    style: CinephileTheme.labelSm(
                      color: CinephileTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: CinephileTheme.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          size: 40,
          color: CinephileTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
