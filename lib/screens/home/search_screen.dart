// ---------------------------------------------------------------------------
// search_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir search & discover screen.
// ---------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../widgets/movie_card.dart';
import '../movie/movie_detail_screen.dart';
import '../../services/watchlist_service.dart';
import 'recommended_movies_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MovieService _movieService = MovieService();
  final WatchlistService _watchlistService = WatchlistService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  List<Movie>? _results;
  bool _isLoading = false;
  String? _errorMessage;

  List<Movie>? _recommendedMovies;
  List<Movie>? _trendingMovies;

  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'id': null},
    {'name': 'Sci-Fi', 'id': 878},
    {'name': 'Action', 'id': 28},
    {'name': 'Thriller', 'id': 53},
    {'name': 'Drama', 'id': 18},
    {'name': 'Horror', 'id': 27},
  ];

  int _selectedYearIndex = 0;
  final List<String> _yearLabels = [
    'Any',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDiscoverData();
  }

  Future<void> _fetchDiscoverData() async {
    try {
      final recommended = await _movieService.fetchPopularMovies(page: 1);
      final trending = await _movieService.fetchPopularMovies(page: 2);
      if (mounted) {
        setState(() {
          _recommendedMovies = recommended.take(3).toList();
          _trendingMovies = trending.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching discover data: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _movieService.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      // If search is cleared, we revert to Discover state (if filters are also empty)
      // or we apply filters.
      _applyFilters();
      return;
    }

    // When typing, clear the filters to avoid confusion
    setState(() {
      _selectedCategoryIndex = 0;
      _selectedYearIndex = 0;
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final movies = await _movieService.searchMovies(query: query);
      if (mounted) {
        setState(() {
          _results = movies;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onCategoryTapped(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _searchController.clear();
    });
    _applyFilters();
  }

  void _onYearTapped(int index) {
    setState(() {
      _selectedYearIndex = index;
      _searchController.clear();
    });
    _applyFilters();
  }

  Future<void> _applyFilters() async {
    if (_selectedCategoryIndex == 0 && _selectedYearIndex == 0 && _searchController.text.isEmpty) {
      setState(() {
        _results = null; // Revert to Bento layout
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      int? genreId = _categories[_selectedCategoryIndex]['id'];
      int? year;
      if (_selectedYearIndex > 0) {
        year = int.tryParse(_yearLabels[_selectedYearIndex]);
      }

      final movies = await _movieService.fetchDiscoverMovies(
        genreIds: genreId != null ? [genreId] : null,
        year: year,
      );

      if (mounted) {
        setState(() {
          _results = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,
      appBar: AppBar(
        backgroundColor: CinephileTheme.background.withAlpha(204),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'CINEPHILE',
          style: CinephileTheme.headlineLgMobile(
            color: CinephileTheme.primary,
          ).copyWith(letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search Bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CinephileTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: CinephileTheme.outlineVariant,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: CinephileTheme.bodyMd(
                        color: CinephileTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Movies, genres, directors...',
                        hintStyle: CinephileTheme.bodyMd(
                          color: CinephileTheme.onSurfaceVariant
                              .withAlpha(128),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: CinephileTheme.outlineVariant,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: CinephileTheme.outlineVariant,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Category Chips ───────────────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedCategoryIndex;
                      return GestureDetector(
                        onTap: () => _onCategoryTapped(index),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CinephileTheme.secondary
                                : CinephileTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isSelected
                                  ? CinephileTheme.secondary
                                  : CinephileTheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            _categories[index]['name'],
                            style: CinephileTheme.labelMd(
                              color: isSelected
                                  ? CinephileTheme.onSecondary
                                  : CinephileTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // ── Year Chips ───────────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _yearLabels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedYearIndex;
                      return GestureDetector(
                        onTap: () => _onYearTapped(index),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CinephileTheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isSelected
                                  ? CinephileTheme.primaryContainer
                                  : CinephileTheme.outlineVariant.withAlpha(128),
                            ),
                          ),
                          child: Text(
                            _yearLabels[index],
                            style: CinephileTheme.labelSm(
                              color: isSelected
                                  ? CinephileTheme.onPrimaryContainer
                                  : CinephileTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Default State: Discover (Bento + List) ───────────────
                if (_results == null && !_isLoading) ...[
                  _buildBentoGrid(),
                  const SizedBox(height: 24),
                  _buildTrendingList(),
                ],

                // ── Loading ──────────────────────────────────────────────
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: CinephileTheme.primaryContainer,
                      ),
                    ),
                  ),

                // ── Error ────────────────────────────────────────────────
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Search failed: $_errorMessage',
                        style: CinephileTheme.bodyMd(
                            color: CinephileTheme.error),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Search/Filter Results Grid ──────────────────────────────────
          if (_results != null && !_isLoading && _errorMessage == null)
            _results!.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No movies found.',
                          style: CinephileTheme.bodyLg(),
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final movie = _results![index];
                          return MovieCard(movie: movie);
                        },
                        childCount: _results!.length,
                      ),
                    ),
                  ),
          
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    if (_recommendedMovies == null || _recommendedMovies!.length < 3) {
      return const SizedBox(); // Loading or insufficient data
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recommended for You',
                  style: CinephileTheme.headlineMd(
                      color: CinephileTheme.primary)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecommendedMoviesScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text('See All',
                        style: CinephileTheme.labelMd(
                            color: CinephileTheme.secondary)),
                    const Icon(Icons.chevron_right,
                        color: CinephileTheme.secondary, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Large Card (Index 0)
              _buildLargeBentoCard(_recommendedMovies![0]),
              const SizedBox(height: 16),
              // 2 Small Cards (Index 1 and 2)
              Row(
                children: [
                  Expanded(child: _buildSmallBentoCard(_recommendedMovies![1])),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSmallBentoCard(_recommendedMovies![2])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeBentoCard(Movie movie) {
    final imageUrl = movie.backdropPath != null
        ? 'https://image.tmdb.org/t/p/w780${movie.backdropPath}'
        : (movie.posterPath != null
            ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}'
            : '');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: CinephileTheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CinephileTheme.surfaceContainerHighest),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.movie, size: 64),
                ),
              // Gradient Overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CinephileTheme.background,
                      CinephileTheme.background.withAlpha(128),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CinephileTheme.surfaceContainer.withAlpha(204),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: CinephileTheme.outlineVariant.withAlpha(128)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: CinephileTheme.starColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: CinephileTheme.labelMd(
                                    color: CinephileTheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          movie.releaseDate?.split('-').first ?? '',
                          style: CinephileTheme.labelMd(
                              color: CinephileTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      style: CinephileTheme.headlineMd(
                          color: CinephileTheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.overview,
                      style: CinephileTheme.bodyMd(
                          color: CinephileTheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBentoCard(Movie movie) {
    final imageUrl = movie.posterPath != null
        ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}'
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: CinephileTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CinephileTheme.surfaceContainerHighest),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.movie, size: 48),
                ),
              // Gradient Overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CinephileTheme.background,
                      CinephileTheme.background.withAlpha(102),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Rating Badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CinephileTheme.background.withAlpha(204),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: CinephileTheme.outlineVariant.withAlpha(128)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          color: CinephileTheme.starColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: CinephileTheme.labelMd(
                            color: CinephileTheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: CinephileTheme.labelMd(
                          color: CinephileTheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.releaseDate?.split('-').first ?? '',
                      style: CinephileTheme.labelMd(
                              color: CinephileTheme.outlineVariant)
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingList() {
    if (_trendingMovies == null || _trendingMovies!.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trending Now',
              style:
                  CinephileTheme.headlineMd(color: CinephileTheme.primary)),
          const SizedBox(height: 16),
          ..._trendingMovies!.map((movie) {
            final imageUrl = movie.posterPath != null
                ? 'https://image.tmdb.org/t/p/w200${movie.posterPath}'
                : '';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(movie: movie),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: CinephileTheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.movie),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: CinephileTheme.labelMd(
                                color: CinephileTheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            movie.releaseDate?.split('-').first ?? 'Unknown',
                            style: CinephileTheme.bodyMd(
                                color: CinephileTheme.outlineVariant)
                                .copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Bookmark
                    IconButton(
                      icon: const Icon(Icons.bookmark_add_outlined,
                          color: CinephileTheme.outlineVariant),
                      onPressed: () async {
                        try {
                          await _watchlistService.toggleWatchlist(movie);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Watchlist updated!', style: TextStyle(color: Colors.white)),
                                backgroundColor: CinephileTheme.surfaceContainerHigh,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot add: Already watched or rated!', style: TextStyle(color: Colors.white)),
                                backgroundColor: CinephileTheme.error,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
