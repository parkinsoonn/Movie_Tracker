// ---------------------------------------------------------------------------
// home_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir home screen with advanced genre + year filtering.
//
// Features:
//   • CINEPHILE branded AppBar with hamburger menu + search icon
//   • "Discover" section header with subtitle
//   • Collapsible filter bar with horizontal genre chips and year selector
//   • 2-column grid of MovieCard widgets fed from TMDb API
//   • Switches between /movie/popular (no filters) and /discover/movie
//     (with genre + year filters) endpoints
//   • Bottom navigation bar (Discover, Watchlist, Social, Profile)
//
// Filtering strategy:
//   Genre + year filtering uses TMDb's /discover/movie endpoint natively.
//   No Firestore composite indexes are needed because the data comes from
//   TMDb's REST API, not from Firestore.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/movie_card.dart';
import '../profile/profile_screen.dart';
import '../watchlist/watchlist_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService _movieService = MovieService();
  late Future<List<Movie>> _moviesFuture;
  int _currentNavIndex = 0;

  // ── Filter State ──────────────────────────────────────────────────────────
  // The active filter selections. When empty, the default /movie/popular
  // endpoint is used. When any filter is set, /discover/movie is called.

  /// Currently selected genre ID, or `null` for "All".
  int? _selectedGenreId;

  /// Currently selected release year, or `null` for "Any".
  int? _selectedYear;

  /// Whether the filter bar is expanded/visible.
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _movieService.fetchPopularMovies();
  }

  /// Re-fetches movies based on the current filter state.
  ///
  /// Uses fetchPopularMovies() when no filters are active (better TMDb ranking),
  /// and fetchDiscoverMovies() when any filter is set.
  void _applyFilters() {
    setState(() {
      final hasFilters = _selectedGenreId != null || _selectedYear != null;

      if (hasFilters) {
        _moviesFuture = _movieService.fetchDiscoverMovies(
          genreIds: _selectedGenreId != null ? [_selectedGenreId!] : null,
          year: _selectedYear,
        );
      } else {
        _moviesFuture = _movieService.fetchPopularMovies();
      }
    });
  }

  /// Clears all active filters and reverts to the default popular feed.
  void _clearFilters() {
    setState(() {
      _selectedGenreId = null;
      _selectedYear = null;
      _moviesFuture = _movieService.fetchPopularMovies();
    });
  }

  bool get _hasActiveFilters =>
      _selectedGenreId != null || _selectedYear != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,

      // ── App Bar ────────────────────────────────────────────────────────────
      // Hidden when Watchlist or Profile tab is active (they have their own AppBars).
      appBar: (_currentNavIndex == 1 || _currentNavIndex == 2 || _currentNavIndex == 3)
          ? null
          : AppBar(
        backgroundColor: CinephileTheme.background.withAlpha(204), // ~80%
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'CINEPHILE',
              style: CinephileTheme.headlineLgMobile(
                color: CinephileTheme.primary,
              ).copyWith(letterSpacing: 2.0),
            ),
          ],
        ),
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: _currentNavIndex == 1
          ? const SearchScreen()
          : _currentNavIndex == 2
              ? WatchlistScreen(
                  onDiscoverTap: () => setState(() => _currentNavIndex = 0),
                )
              : _currentNavIndex == 3
                  ? const ProfileScreen()
                  : _buildDiscoverBody(),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: CinephileTheme.surfaceContainer.withAlpha(204),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.search, Icons.search, 'Search'),
              _buildNavItem(2, Icons.bookmark_outline, Icons.bookmark, 'Watchlist'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentNavIndex == index;
    if (isSelected) {
      return GestureDetector(
        onTap: () => setState(() => _currentNavIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: CinephileTheme.primaryContainer,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activeIcon, color: CinephileTheme.onPrimaryContainer, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: CinephileTheme.labelSm(color: CinephileTheme.onPrimaryContainer).copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => setState(() => _currentNavIndex = index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: CinephileTheme.onSurfaceVariant, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: CinephileTheme.labelSm(color: CinephileTheme.onSurfaceVariant).copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVER BODY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDiscoverBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CinephileTheme.spacingContainerPadding,
            CinephileTheme.spacingStackMd,
            CinephileTheme.spacingContainerPadding,
            CinephileTheme.spacingGutter,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover',
                      style: CinephileTheme.headlineMd(
                        color: CinephileTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your private screening starts here.',
                      style: CinephileTheme.bodyMd(
                        color: CinephileTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Filter toggle button
              GestureDetector(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _showFilters || _hasActiveFilters
                        ? CinephileTheme.primaryContainer.withAlpha(20)
                        : CinephileTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
                    border: Border.all(
                      color: _hasActiveFilters
                          ? CinephileTheme.primaryContainer.withAlpha(80)
                          : CinephileTheme.outlineVariant.withAlpha(40),
                    ),
                  ),
                  child: Icon(
                    _hasActiveFilters
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                    size: 20,
                    color: _hasActiveFilters
                        ? CinephileTheme.primaryContainer
                        : CinephileTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Filter Bar (collapsible) ─────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _showFilters
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildFilterBar(),
          secondChild: const SizedBox.shrink(),
        ),

        // ── Active filter chips ──────────────────────────────────────────
        if (_hasActiveFilters && !_showFilters)
          _buildActiveFilterChips(),

        // ── Movie grid ───────────────────────────────────────────────────
        Expanded(
          child: FutureBuilder<List<Movie>>(
            future: _moviesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: CinephileTheme.primaryContainer,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      CinephileTheme.spacingContainerPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: CinephileTheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load movies',
                          style: CinephileTheme.headlineMd(
                            color: CinephileTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: CinephileTheme.bodyMd(
                            color: CinephileTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CinephileTheme.primaryContainer,
                            foregroundColor: CinephileTheme.background,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.movie_filter_outlined,
                        size: 48,
                        color: CinephileTheme.onSurfaceVariant.withAlpha(100),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No movies found for these filters.',
                        style: CinephileTheme.bodyMd(
                          color: CinephileTheme.onSurfaceVariant,
                        ),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _clearFilters,
                          child: Text(
                            'Clear Filters',
                            style: CinephileTheme.labelMd(
                              color: CinephileTheme.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final movies = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: CinephileTheme.spacingGutter,
                  mainAxisSpacing: CinephileTheme.spacingStackMd,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  return MovieCard(movie: movies[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFilterBar() {
    final currentYear = DateTime.now().year;
    // Generate year list: current year → 1970
    final years = List.generate(currentYear - 1969, (i) => currentYear - i);

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Genre chips ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
              left: CinephileTheme.spacingContainerPadding,
              bottom: 8,
            ),
            child: Text(
              'GENRE',
              style: CinephileTheme.labelSm(
                color: CinephileTheme.onSurfaceVariant,
              ).copyWith(fontSize: 10, letterSpacing: 1.5),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
              ),
              children: [
                // "All" chip
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedGenreId == null,
                  onTap: () {
                    _selectedGenreId = null;
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                // Genre chips from the shared genre map
                ...WatchlistService.genreMap.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: entry.value,
                      isSelected: _selectedGenreId == entry.key,
                      onTap: () {
                        _selectedGenreId = entry.key;
                        _applyFilters();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Year selector ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
              left: CinephileTheme.spacingContainerPadding,
              bottom: 8,
            ),
            child: Text(
              'RELEASE YEAR',
              style: CinephileTheme.labelSm(
                color: CinephileTheme.onSurfaceVariant,
              ).copyWith(fontSize: 10, letterSpacing: 1.5),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
              ),
              children: [
                // "Any" chip
                _FilterChip(
                  label: 'Any',
                  isSelected: _selectedYear == null,
                  onTap: () {
                    _selectedYear = null;
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                // Year chips
                ...years.map((year) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: year.toString(),
                      isSelected: _selectedYear == year,
                      onTap: () {
                        _selectedYear = year;
                        _applyFilters();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Clear Filters button ───────────────────────────────────────
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
              ),
              child: GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CinephileTheme.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CinephileTheme.error.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, size: 16, color: CinephileTheme.error),
                      const SizedBox(width: 6),
                      Text(
                        'Clear All Filters',
                        style: CinephileTheme.labelSm(
                          color: CinephileTheme.error,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVE FILTER CHIPS (shown when filter bar is collapsed)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActiveFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CinephileTheme.spacingContainerPadding,
        0,
        CinephileTheme.spacingContainerPadding,
        12,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (_selectedGenreId != null)
            _buildActiveChip(
              label: WatchlistService.genreName(_selectedGenreId!),
              onClear: () {
                _selectedGenreId = null;
                _applyFilters();
              },
            ),
          if (_selectedYear != null)
            _buildActiveChip(
              label: _selectedYear.toString(),
              onClear: () {
                _selectedYear = null;
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActiveChip({
    required String label,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: CinephileTheme.ctaGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: CinephileTheme.labelSm(color: Colors.white)
                .copyWith(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(50),
              ),
              child: const Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER CHIP COMPONENT
// ═══════════════════════════════════════════════════════════════════════════════

/// A single selectable chip used in the genre and year filter rows.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CinephileTheme.primaryContainer.withAlpha(25)
              : CinephileTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? CinephileTheme.primaryContainer.withAlpha(120)
                : CinephileTheme.outlineVariant.withAlpha(60),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: CinephileTheme.labelSm(
            color: isSelected
                ? CinephileTheme.primaryContainer
                : CinephileTheme.onSurfaceVariant,
          ).copyWith(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}