// ---------------------------------------------------------------------------
// profile_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir profile screen with tabbed content.
//
// Layout (top → bottom):
//   1. Profile Header — avatar, name, email, join date, stats row
//   2. Pinned TabBar — "Watched" / "Rated" tabs with gold indicator
//   3. TabBarView — StreamBuilder-driven lists for each tab
//
// Technical choices:
//   • NestedScrollView + SliverToBoxAdapter keeps the header scrollable while
//     the TabBarView body scrolls independently within each tab.
//   • StreamBuilder (not FutureBuilder) for movie lists — gives real-time
//     updates without pull-to-refresh boilerplate.
//   • Shimmer skeletons for loading; illustrated empty states for empty lists.
// ---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/rated_movie.dart';
import '../../models/watched_movie.dart';
import '../../services/profile_service.dart';
import '../../services/movie_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../movie/movie_detail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final MovieService _movieService = MovieService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Ensure the user document exists on first visit.
    _profileService.ensureUserDocument();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _movieService.dispose();
    super.dispose();
  }

  Future<void> _navigateToMovie(int movieId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: CinephileTheme.primaryContainer),
      ),
    );

    try {
      final fullMovie = await _movieService.fetchMovieDetails(movieId: movieId);
      
      if (mounted) {
        Navigator.pop(context); // close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: fullMovie),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load movie details.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: CinephileTheme.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            centerTitle: true,
            title: Text(
              'PROFILE',
              style: CinephileTheme.headlineLgMobile(
                color: CinephileTheme.primary,
              ).copyWith(letterSpacing: 2.0),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: CinephileTheme.onSurfaceVariant,
                ),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Profile Header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildProfileHeader(),
          ),

          // ── Pinned Tab Bar ───────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                indicatorColor: CinephileTheme.primaryContainer,
                indicatorWeight: 3.0,
                labelColor: CinephileTheme.primaryContainer,
                unselectedLabelColor: CinephileTheme.onSurfaceVariant,
                labelStyle: CinephileTheme.labelMd(),
                unselectedLabelStyle: CinephileTheme.labelMd(),
                tabs: const [
                  Tab(icon: Icon(Icons.visibility), text: 'Watched'),
                  Tab(icon: Icon(Icons.star_rounded), text: 'Rated'),
                ],
              ),
            ),
          ),
        ],

        // ── Tab Bodies ───────────────────────────────────────────────────────
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWatchedTab(),
            _buildRatedTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _profileService.getUserProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildHeaderShimmer();
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final user = FirebaseAuth.instance.currentUser;

        final displayName = data['displayName'] as String? ??
            user?.displayName ??
            user?.email?.split('@').first ??
            'Cinephile';
        final email = data['email'] as String? ?? user?.email ?? '';
        final photoUrl = data['photoUrl'] as String? ?? user?.photoURL;
        final joinedAt = (data['joinedAt'] as Timestamp?)?.toDate();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CinephileTheme.spacingContainerPadding,
            vertical: CinephileTheme.spacingStackMd,
          ),
          child: Column(
            children: [
              // ── Avatar with gradient ring ──────────────────────────────
              _buildAvatar(photoUrl),
              const SizedBox(height: CinephileTheme.spacingGutter),

              // ── Name ──────────────────────────────────────────────────
              Text(
                displayName,
                style: CinephileTheme.headlineMd(
                  color: CinephileTheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),

              // ── Email ─────────────────────────────────────────────────
              Text(
                email,
                style: CinephileTheme.labelSm(
                  color: CinephileTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // ── Join date ─────────────────────────────────────────────
              if (joinedAt != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: CinephileTheme.primaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Member since ${_formatDate(joinedAt)}',
                      style: CinephileTheme.labelSm(
                        color: CinephileTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: CinephileTheme.spacingStackMd),

              // ── Stats row ─────────────────────────────────────────────
              _buildStatsRow(),
            ],
          ),
        );
      },
    );
  }

  /// Circular avatar wrapped in a gradient-stroked ring.
  Widget _buildAvatar(String? photoUrl) {
    return Container(
      padding: const EdgeInsets.all(3), // ring thickness
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: CinephileTheme.ctaGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(2), // inner gap
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CinephileTheme.background,
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: CinephileTheme.surfaceContainerHigh,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? const Icon(
                  Icons.person,
                  size: 48,
                  color: CinephileTheme.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }

  /// Three glass-card stat pills showing watched count, rated count, and
  /// average rating — all driven by real-time Firestore streams.
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Watched count
        Expanded(
          child: StreamBuilder<List<WatchedMovie>>(
            stream: _profileService.getWatchedMoviesStream(),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return _statPill(
                icon: Icons.visibility,
                value: '$count',
                label: 'Watched',
                iconColor: CinephileTheme.primary,
              );
            },
          ),
        ),
        const SizedBox(width: CinephileTheme.spacingGutter),

        // Rated count
        Expanded(
          child: StreamBuilder<List<RatedMovie>>(
            stream: _profileService.getRatedMoviesStream(),
            builder: (context, snap) {
              final movies = snap.data ?? [];
              return _statPill(
                icon: Icons.rate_review,
                value: '${movies.length}',
                label: 'Rated',
                iconColor: CinephileTheme.tertiary,
              );
            },
          ),
        ),
      ],
    );
  }

  /// A single stat indicator with a frosted-glass appearance.
  Widget _statPill({
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: CinephileTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CinephileTheme.surfaceContainerLow,
            ),
            child: Icon(icon, size: 16, color: iconColor ?? CinephileTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: CinephileTheme.labelSm(
              color: CinephileTheme.onSurfaceVariant,
            ).copyWith(letterSpacing: 1.2, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: CinephileTheme.displayLg(
              color: CinephileTheme.onSurface,
            ).copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  /// Shimmer placeholder while the profile header is loading.
  Widget _buildHeaderShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CinephileTheme.spacingContainerPadding,
        vertical: CinephileTheme.spacingStackMd,
      ),
      child: Column(
        children: [
          const ShimmerLoading(
            width: 100,
            height: 100,
            borderRadius: 50,
          ),
          const SizedBox(height: 16),
          ShimmerLoading(width: 140, height: 20),
          const SizedBox(height: 8),
          ShimmerLoading(width: 180, height: 14),
          const SizedBox(height: 8),
          ShimmerLoading(width: 160, height: 14),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ShimmerLoading(
                  width: 80,
                  height: 70,
                  borderRadius: CinephileTheme.radiusLg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WATCHED TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWatchedTab() {
    return StreamBuilder<List<WatchedMovie>>(
      stream: _profileService.getWatchedMoviesStream(),
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWatchedShimmer();
        }

        // ── Error ──
        if (snapshot.hasError) {
          return _buildErrorState('Could not load watched movies.');
        }

        // ── Empty ──
        final movies = snapshot.data ?? [];
        if (movies.isEmpty) {
          return _buildEmptyState(
            icon: Icons.visibility_off_outlined,
            title: 'No movies watched yet',
            subtitle:
                'Start exploring and mark movies as watched\nto build your collection.',
          );
        }

        // ── Data ──
        return GridView.builder(
          padding: const EdgeInsets.all(CinephileTheme.spacingContainerPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return _buildWatchedCard(movies[index], index);
          },
        );
      },
    );
  }

  /// A single watched-movie poster card with title below and staggered
  /// fade-in animation.
  Widget _buildWatchedCard(WatchedMovie movie, int index) {
    return TweenAnimationBuilder<double>(
      // Stagger the entrance animation by 50 ms per card.
      duration: Duration(milliseconds: 400 + (index * 50)),
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
      child: GestureDetector(
        onTap: () => _navigateToMovie(movie.movieId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster ───────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CinephileTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
                  border: Border.all(
                    color: Colors.white.withAlpha(13),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: movie.fullPosterUrl != null
                    ? Image.network(
                        movie.fullPosterUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, e, s) => _posterPlaceholder(),
                      )
                    : _posterPlaceholder(),
              ),
            ),
            const SizedBox(height: 6),

            // ── Title ────────────────────────────────────────────────────
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CinephileTheme.labelSm(
                color: CinephileTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer grid skeleton for the watched tab.
  Widget _buildWatchedShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(CinephileTheme.spacingContainerPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerLoading(
              height: double.infinity,
              borderRadius: CinephileTheme.radiusMd,
            ),
          ),
          const SizedBox(height: 6),
          ShimmerLoading(width: 80, height: 12),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RATED TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRatedTab() {
    return StreamBuilder<List<RatedMovie>>(
      stream: _profileService.getRatedMoviesStream(),
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRatedShimmer();
        }

        // ── Error ──
        if (snapshot.hasError) {
          return _buildErrorState('Could not load rated movies.');
        }

        // ── Empty ──
        final movies = snapshot.data ?? [];
        if (movies.isEmpty) {
          return _buildEmptyState(
            icon: Icons.star_outline_rounded,
            title: 'No ratings yet',
            subtitle:
                'Watch a movie and rate it to see\nyour personal scores here.',
          );
        }

        // ── Data ──
        return ListView.builder(
          padding: const EdgeInsets.all(CinephileTheme.spacingContainerPadding),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return _buildRatedCard(movies[index], index);
          },
        );
      },
    );
  }

  /// A rated-movie card showing poster, title, and a gold star rating badge.
  Widget _buildRatedCard(RatedMovie movie, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
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
        onTap: () => _navigateToMovie(movie.movieId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CinephileTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
            border: Border.all(
              color: CinephileTheme.outlineVariant.withAlpha(60),
            ),
          ),
          child: Row(
            children: [
              // ── Poster thumbnail ───────────────────────────────────────
              Container(
                width: 56,
                height: 84,
                decoration: BoxDecoration(
                  color: CinephileTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(CinephileTheme.radiusSm),
                ),
                clipBehavior: Clip.antiAlias,
                child: movie.fullPosterUrl != null
                    ? Image.network(
                        movie.fullPosterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => _posterPlaceholder(),
                      )
                    : _posterPlaceholder(),
              ),
              const SizedBox(width: 14),

              // ── Title + date ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CinephileTheme.labelMd(
                        color: CinephileTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rated on ${_formatDate(movie.ratedAt)}',
                      style: CinephileTheme.labelSm(
                        color: CinephileTheme.onSurfaceVariant,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Gold rating badge ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CinephileTheme.primaryContainer.withAlpha(25),
                  borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
                  border: Border.all(
                    color: CinephileTheme.primaryContainer.withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: CinephileTheme.starColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.formattedRating,
                      style: CinephileTheme.labelMd(
                        color: CinephileTheme.starColor,
                      ).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
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

  /// Shimmer list skeleton for the rated tab.
  Widget _buildRatedShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(CinephileTheme.spacingContainerPadding),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CinephileTheme.surfaceContainerHigh.withAlpha(80),
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        ),
        child: Row(
          children: [
            ShimmerLoading(
              width: 56,
              height: 84,
              borderRadius: CinephileTheme.radiusSm,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(width: 140, height: 14),
                  const SizedBox(height: 8),
                  ShimmerLoading(width: 100, height: 10),
                ],
              ),
            ),
            ShimmerLoading(
              width: 70,
              height: 32,
              borderRadius: CinephileTheme.radiusMd,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Elegant empty-state with animated fade-in.
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            // Large muted icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CinephileTheme.surfaceContainerHigh.withAlpha(120),
              ),
              child: Icon(
                icon,
                size: 48,
                color: CinephileTheme.onSurfaceVariant.withAlpha(120),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: CinephileTheme.headlineMd(
                color: CinephileTheme.onSurface,
              ).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: CinephileTheme.bodyMd(
                color: CinephileTheme.onSurfaceVariant,
              ).copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Inline error state.
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: CinephileTheme.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: CinephileTheme.bodyMd(color: CinephileTheme.onSurface),
          ),
        ],
      ),
    );
  }

  /// Generic poster fallback icon.
  Widget _posterPlaceholder() {
    return Container(
      color: CinephileTheme.surfaceContainer,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          size: 28,
          color: CinephileTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Formats a [DateTime] as "Jan 2024".
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STICKY TAB BAR DELEGATE
// ═════════════════════════════════════════════════════════════════════════════

/// A [SliverPersistentHeaderDelegate] that pins the [TabBar] at the top of
/// the scroll view once the header scrolls out of view.
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _StickyTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: CinephileTheme.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
