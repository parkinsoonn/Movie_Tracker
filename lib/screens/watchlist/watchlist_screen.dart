// ---------------------------------------------------------------------------
// watchlist_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir watchlist screen with genre filtering.
//
// Architecture:
//   • StatefulWidget manages the active genre filter state.
//   • A SINGLE StreamBuilder on `getWatchlistStream()` drives the entire UI.
//   • When "All" is selected (default), movies are displayed in genre-grouped
//     horizontal sections — the original layout.
//   • When a specific genre is selected, a client-side `where()` filter
//     produces a flat list displayed in a 2-column grid.
//   • Client-side filtering was chosen because:
//     - Watchlists are per-user and typically small (tens to hundreds).
//     - The data is already loaded from a single Firestore stream.
//     - No additional Firestore reads, indexes, or queries are needed.
//   • The filter bottom sheet dynamically lists only genres present in the
//     user's current watchlist.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/movie.dart';
import '../../models/watchlist_movie.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../movie/movie_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  /// Optional callback to switch the bottom nav to the Discover tab.
  final VoidCallback? onDiscoverTap;

  const WatchlistScreen({super.key, this.onDiscoverTap});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistService _service = WatchlistService();

  /// Currently active genre filter.
  /// `null` means "All" — no filter applied (genre-grouped view).
  String? _selectedGenre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Filter Icon ──────────────────────────────────
          SliverAppBar(
            backgroundColor: CinephileTheme.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text(
              'WATCHLIST',
              style: CinephileTheme.headlineLgMobile(
                color: CinephileTheme.primary,
              ).copyWith(letterSpacing: 2.0),
            ),
            actions: [
              // Filter icon — opens genre selection bottom sheet.
              IconButton(
                icon: Icon(
                  _selectedGenre != null
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  color: _selectedGenre != null
                      ? CinephileTheme.primaryContainer
                      : CinephileTheme.onSurfaceVariant,
                ),
                tooltip: 'Filter by genre',
                onPressed: () => _showFilterSheet(context),
              ),
            ],
          ),

          // ── Active filter chip ─────────────────────────────────────────
          if (_selectedGenre != null)
            SliverToBoxAdapter(
              child: _ActiveFilterChip(
                genre: _selectedGenre!,
                onClear: () => setState(() => _selectedGenre = null),
              ),
            ),

          // ── Stream-driven body ─────────────────────────────────────────
          _WatchlistBody(
            service: _service,
            selectedGenre: _selectedGenre,
            onDiscoverTap: widget.onDiscoverTap,
          ),
        ],
      ),
    );
  }

  // ── Filter Bottom Sheet ──────────────────────────────────────────────────

  /// Opens a cinematic bottom sheet listing all genres present in the user's
  /// watchlist. Selecting a genre updates `_selectedGenre` and reactively
  /// re-filters the displayed movies.
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CinephileTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CinephileTheme.radiusXxl),
        ),
      ),
      builder: (context) {
        return StreamBuilder<List<WatchlistMovie>>(
          stream: _service.getWatchlistStream(),
          builder: (context, snapshot) {
            // Extract unique genre names from the current watchlist.
            final movies = snapshot.data ?? [];
            final genreSet = <String>{};
            for (final movie in movies) {
              if (movie.genreIds.isEmpty) {
                genreSet.add('Other');
              } else {
                for (final id in movie.genreIds) {
                  genreSet.add(WatchlistService.genreName(id));
                }
              }
            }
            final genres = genreSet.toList()..sort();

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CinephileTheme.onSurfaceVariant.withAlpha(80),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Filter by Genre',
                        style: CinephileTheme.headlineMd(
                          color: CinephileTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show only movies from a specific genre',
                        style: CinephileTheme.bodyMd(
                          color: CinephileTheme.onSurfaceVariant,
                        ).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // Scrollable options list
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // "All" option
                              _FilterOption(
                                label: 'All Genres',
                                isSelected: _selectedGenre == null,
                                onTap: () {
                                  setState(() => _selectedGenre = null);
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(height: 8),

                              // Genre options
                              ...genres.map((genre) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _FilterOption(
                                      label: genre,
                                      isSelected: _selectedGenre == genre,
                                      onTap: () {
                                        setState(() => _selectedGenre = genre);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  )),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER UI COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

/// A single selectable option inside the genre filter bottom sheet.
class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? CinephileTheme.primaryContainer.withAlpha(20)
                : CinephileTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
            border: Border.all(
              color: isSelected
                  ? CinephileTheme.primaryContainer.withAlpha(100)
                  : CinephileTheme.outlineVariant.withAlpha(40),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: isSelected
                    ? CinephileTheme.primaryContainer
                    : CinephileTheme.onSurfaceVariant.withAlpha(120),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: CinephileTheme.labelMd(
                    color: isSelected
                        ? CinephileTheme.primaryContainer
                        : CinephileTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated chip shown below the AppBar when a genre filter is active.
class _ActiveFilterChip extends StatelessWidget {
  final String genre;
  final VoidCallback onClear;

  const _ActiveFilterChip({required this.genre, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CinephileTheme.spacingContainerPadding,
        4,
        CinephileTheme.spacingContainerPadding,
        8,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: CinephileTheme.ctaGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_alt, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  genre,
                  style: CinephileTheme.labelSm(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(50),
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STREAM-DRIVEN BODY
// ═══════════════════════════════════════════════════════════════════════════════

/// Manages the stream and delegates to either the grouped view (no filter)
/// or the filtered grid view (genre selected).
class _WatchlistBody extends StatelessWidget {
  final WatchlistService service;
  final String? selectedGenre;
  final VoidCallback? onDiscoverTap;

  const _WatchlistBody({
    required this.service,
    required this.selectedGenre,
    this.onDiscoverTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WatchlistMovie>>(
      stream: service.getWatchlistStream(),
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerSliver();
        }

        // ── Error ──
        if (snapshot.hasError) {
          return SliverFillRemaining(child: _buildErrorState());
        }

        // ── Empty ──
        final allMovies = snapshot.data ?? [];
        if (allMovies.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(context),
          );
        }

        // ── Filtered View (specific genre selected) ──
        if (selectedGenre != null) {
          return _buildFilteredGrid(allMovies);
        }

        // ── Grouped View (no filter — default) ──
        return _buildGroupedSections(allMovies);
      },
    );
  }

  // ── Filtered Grid ──────────────────────────────────────────────────────

  /// Client-side filter: keep only movies that contain the selected genre.
  SliverPadding _buildFilteredGrid(List<WatchlistMovie> allMovies) {
    final filtered = allMovies.where((movie) {
      if (movie.genreIds.isEmpty && selectedGenre == 'Other') return true;
      return movie.genreIds
          .map((id) => WatchlistService.genreName(id))
          .contains(selectedGenre);
    }).toList();

    if (filtered.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.zero,
        sliver: SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off,
                  size: 48,
                  color: CinephileTheme.onSurfaceVariant.withAlpha(100),
                ),
                const SizedBox(height: 12),
                Text(
                  'No movies in "$selectedGenre"',
                  style: CinephileTheme.bodyMd(
                    color: CinephileTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: CinephileTheme.spacingContainerPadding,
        vertical: CinephileTheme.spacingStackSm,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: CinephileTheme.spacingGutter,
          mainAxisSpacing: CinephileTheme.spacingStackMd,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _WatchlistGridCard(
            movie: filtered[index],
            index: index,
          ),
          childCount: filtered.length,
        ),
      ),
    );
  }

  // ── Grouped Sections ───────────────────────────────────────────────────

  /// The original genre-grouped horizontal layout (shown when no filter).
  SliverList _buildGroupedSections(List<WatchlistMovie> allMovies) {
    // Group movies by genre client-side.
    final Map<String, List<WatchlistMovie>> grouped = {};
    for (final movie in allMovies) {
      if (movie.genreIds.isEmpty) {
        grouped.putIfAbsent('Other', () => []).add(movie);
      } else {
        for (final genreId in movie.genreIds) {
          final name = WatchlistService.genreName(genreId);
          grouped.putIfAbsent(name, () => []).add(movie);
        }
      }
    }
    final genres = grouped.keys.toList()..sort();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final genre = genres[index];
          final movies = grouped[genre]!;
          return _GenreSection(genre: genre, movies: movies, index: index);
        },
        childCount: genres.length,
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CinephileTheme.surfaceContainerHigh.withAlpha(120),
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 48,
                color: CinephileTheme.onSurfaceVariant.withAlpha(120),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your watchlist is empty',
              style: CinephileTheme.headlineMd(
                color: CinephileTheme.onSurface,
              ).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover new movies and add them\nto your watchlist to see them here.',
              textAlign: TextAlign.center,
              style: CinephileTheme.bodyMd(
                color: CinephileTheme.onSurfaceVariant,
              ).copyWith(fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (onDiscoverTap != null)
              Container(
                decoration: BoxDecoration(
                  gradient: CinephileTheme.ctaGradient,
                  borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
                ),
                child: ElevatedButton.icon(
                  onPressed: onDiscoverTap,
                  icon: const Icon(Icons.movie_outlined, color: Colors.white),
                  label: Text(
                    'Discover Movies',
                    style: CinephileTheme.headlineMd(color: Colors.white)
                        .copyWith(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(CinephileTheme.radiusMd),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: CinephileTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(
            'Could not load your watchlist.',
            style: CinephileTheme.bodyMd(color: CinephileTheme.onSurface),
          ),
        ],
      ),
    );
  }

  // ── Shimmer Loading ─────────────────────────────────────────────────────

  SliverToBoxAdapter _buildShimmerSliver() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (sectionIndex) {
          return Padding(
            padding: const EdgeInsets.only(top: CinephileTheme.spacingStackMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CinephileTheme.spacingContainerPadding,
                  ),
                  child: ShimmerLoading(width: 120, height: 20),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      left: CinephileTheme.spacingContainerPadding,
                    ),
                    itemCount: 4,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading(
                            width: 120,
                            height: 160,
                            borderRadius: CinephileTheme.radiusMd,
                          ),
                          const SizedBox(height: 8),
                          ShimmerLoading(width: 90, height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GENRE SECTION (for grouped view)
// ═══════════════════════════════════════════════════════════════════════════════

class _GenreSection extends StatelessWidget {
  final String genre;
  final List<WatchlistMovie> movies;
  final int index;

  const _GenreSection({
    required this.genre,
    required this.movies,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CinephileTheme.spacingContainerPadding,
              CinephileTheme.spacingStackMd,
              CinephileTheme.spacingContainerPadding,
              CinephileTheme.spacingStackSm,
            ),
            child: Row(
              children: [
                Text(
                  genre,
                  style: CinephileTheme.headlineMd(
                    color: CinephileTheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: CinephileTheme.primaryContainer.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CinephileTheme.primaryContainer.withAlpha(60),
                    ),
                  ),
                  child: Text(
                    '${movies.length}',
                    style: CinephileTheme.labelSm(
                      color: CinephileTheme.primaryContainer,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Horizontal Poster List ──────────────────────────────────────
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: CinephileTheme.spacingContainerPadding,
                right: CinephileTheme.spacingBase,
              ),
              itemCount: movies.length,
              itemBuilder: (context, i) {
                return _WatchlistPosterCard(movie: movies[i], index: i);
              },
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CinephileTheme.spacingContainerPadding,
            ),
            child: Divider(
              color: CinephileTheme.outlineVariant.withAlpha(40),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POSTER CARD (horizontal list)
// ═══════════════════════════════════════════════════════════════════════════════

class _WatchlistPosterCard extends StatelessWidget {
  final WatchlistMovie movie;
  final int index;

  const _WatchlistPosterCard({required this.movie, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPoster()),
            const SizedBox(height: 6),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CinephileTheme.labelSm(color: CinephileTheme.onSurface),
            ),
            if (movie.year.isNotEmpty)
              Text(
                movie.year,
                style: CinephileTheme.labelSm(
                  color: CinephileTheme.onSurfaceVariant,
                ).copyWith(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return Container(
      decoration: BoxDecoration(
        color: CinephileTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (movie.fullPosterUrl != null)
            Image.network(
              movie.fullPosterUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => _posterPlaceholder(),
            )
          else
            _posterPlaceholder(),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    CinephileTheme.background.withAlpha((0.85 * 255).toInt()),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: CinephileTheme.primaryContainer, size: 14),
                const SizedBox(width: 3),
                Text(
                  movie.voteAverage.toStringAsFixed(1),
                  style: CinephileTheme.labelSm(
                    color: CinephileTheme.primaryContainer,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    final movieModel = Movie(
      id: movie.movieId,
      title: movie.title,
      overview: '',
      posterPath: movie.posterPath,
      voteAverage: movie.voteAverage,
      voteCount: 0,
      releaseDate: movie.releaseDate,
      popularity: 0,
      genreIds: movie.genreIds,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movieModel)),
    );
  }

  static Widget _posterPlaceholder() {
    return Container(
      color: CinephileTheme.surfaceContainer,
      child: const Center(
        child: Icon(Icons.movie_outlined, size: 28, color: CinephileTheme.onSurfaceVariant),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRID CARD (for filtered view)
// ═══════════════════════════════════════════════════════════════════════════════

/// Larger card used in the 2-column grid when a genre filter is active.
class _WatchlistGridCard extends StatelessWidget {
  final WatchlistMovie movie;
  final int index;

  const _WatchlistGridCard({required this.movie, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          final movieModel = Movie(
            id: movie.movieId,
            title: movie.title,
            overview: '',
            posterPath: movie.posterPath,
            voteAverage: movie.voteAverage,
            voteCount: 0,
            releaseDate: movie.releaseDate,
            popularity: 0,
            genreIds: movie.genreIds,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movie: movieModel),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CinephileTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (movie.fullPosterUrl != null)
                      Image.network(
                        movie.fullPosterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => Container(
                          color: CinephileTheme.surfaceContainer,
                          child: const Center(
                            child: Icon(
                              Icons.movie_outlined,
                              size: 36,
                              color: CinephileTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: CinephileTheme.surfaceContainer,
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            size: 36,
                            color: CinephileTheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    // Bottom gradient
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              CinephileTheme.background
                                  .withAlpha((0.85 * 255).toInt()),
                            ],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Rating badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: CinephileTheme.primaryContainer,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            movie.voteAverage.toStringAsFixed(1),
                            style: CinephileTheme.labelSm(
                              color: CinephileTheme.primaryContainer,
                            ).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CinephileTheme.labelSm(color: CinephileTheme.onSurface),
            ),

            // Year
            if (movie.year.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  movie.year,
                  style: CinephileTheme.labelSm(
                    color: CinephileTheme.onSurfaceVariant,
                  ).copyWith(fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
