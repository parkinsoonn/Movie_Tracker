// ---------------------------------------------------------------------------
// actor_detail_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir actor detail screen — displays biography and filmography.
//
// Features:
//   • Hero profile image in SliverAppBar with gradient fade
//   • Actor name, birth date, birthplace, age
//   • Expandable biography section with "Read More" toggle
//   • Filmography grid sorted by vote_average (highest first)
//   • Reuses MovieCard for consistent film presentation
//   • Full loading, error, and empty states
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/actor_detail.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../widgets/movie_card.dart';

class ActorDetailScreen extends StatefulWidget {
  /// The TMDb person ID for the actor to display.
  final int personId;

  /// The actor's name — shown in the AppBar while data loads.
  final String actorName;

  const ActorDetailScreen({
    super.key,
    required this.personId,
    required this.actorName,
  });

  @override
  State<ActorDetailScreen> createState() => _ActorDetailScreenState();
}

class _ActorDetailScreenState extends State<ActorDetailScreen> {
  final MovieService _movieService = MovieService();
  late Future<_ActorData> _dataFuture;
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchActorData();
  }

  @override
  void dispose() {
    _movieService.dispose();
    super.dispose();
  }

  Future<_ActorData> _fetchActorData() async {
    final results = await Future.wait([
      _movieService.fetchActorDetails(personId: widget.personId),
      _movieService.fetchActorMovies(personId: widget.personId),
    ]);
    return _ActorData(
      detail: results[0] as ActorDetail,
      movies: results[1] as List<Movie>,
    );
  }

  void _retry() {
    setState(() {
      _dataFuture = _fetchActorData();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,
      body: FutureBuilder<_ActorData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          // Error
          if (snapshot.hasError) {
            return _buildError();
          }

          // Success
          final data = snapshot.data!;
          return _buildContent(data.detail, data.movies);
        },
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          backgroundColor: CinephileTheme.background,
          leading: _backButton(),
          title: Text(
            widget.actorName,
            style: CinephileTheme.headlineMd(color: CinephileTheme.onSurface),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: CinephileTheme.surfaceContainer),
          ),
        ),
        const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(
              color: CinephileTheme.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────

  Widget _buildError() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: CinephileTheme.background,
          leading: _backButton(),
          title: Text(
            widget.actorName,
            style: CinephileTheme.headlineMd(color: CinephileTheme.onSurface),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(CinephileTheme.spacingContainerPadding),
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
                    'Failed to load actor details',
                    style: CinephileTheme.headlineMd(
                      color: CinephileTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CinephileTheme.primaryContainer,
                      foregroundColor: CinephileTheme.background,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Success Content ────────────────────────────────────────────────────────

  Widget _buildContent(ActorDetail actor, List<Movie> movies) {
    final profileUrl = actor.fullProfileUrl;

    return CustomScrollView(
      slivers: [
        // ── Hero Profile Image ─────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 420,
          pinned: true,
          backgroundColor: CinephileTheme.background,
          leading: _backButton(),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Profile image
                if (profileUrl != null)
                  Image.network(
                    profileUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withAlpha(60),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, e, s) =>
                        Container(color: CinephileTheme.surfaceContainer),
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
                        CinephileTheme.background.withAlpha(180),
                        CinephileTheme.background,
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Actor Info Section ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CinephileTheme.spacingContainerPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  actor.name,
                  style: CinephileTheme.displayLg(
                    color: CinephileTheme.onSurface,
                  ).copyWith(fontSize: 32),
                ),
                const SizedBox(height: CinephileTheme.spacingStackSm),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (actor.knownForDepartment.isNotEmpty)
                      _infoChip(Icons.movie_outlined, actor.knownForDepartment),
                    if (actor.formattedBirthday != null)
                      _infoChip(Icons.cake_outlined, actor.formattedBirthday!),
                    if (actor.age != null)
                      _infoChip(
                        Icons.person_outline,
                        actor.deathday != null
                            ? 'Died at ${actor.age}'
                            : 'Age ${actor.age}',
                      ),
                    if (actor.placeOfBirth != null)
                      _infoChip(Icons.place_outlined, actor.placeOfBirth!),
                  ],
                ),

                const SizedBox(height: CinephileTheme.spacingStackLg),

                // Biography
                if (actor.biography.isNotEmpty) ...[
                  Text(
                    'Biography',
                    style: CinephileTheme.headlineLg(
                      color: CinephileTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: CinephileTheme.spacingStackSm),
                  Text(
                    actor.biography,
                    maxLines: _bioExpanded ? null : 5,
                    overflow: _bioExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: CinephileTheme.bodyLg(
                      color: CinephileTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _bioExpanded = !_bioExpanded),
                    child: Text(
                      _bioExpanded ? 'Show Less' : 'Read More',
                      style: CinephileTheme.labelMd(
                        color: CinephileTheme.primaryContainer,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CinephileTheme.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(CinephileTheme.radiusLg),
                      border: Border.all(
                        color: Colors.white.withAlpha(10),
                      ),
                    ),
                    child: Text(
                      'No biography available.',
                      style: CinephileTheme.bodyMd(
                        color: CinephileTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: CinephileTheme.spacingStackLg),

                // Divider
                Divider(color: Colors.white.withAlpha(15), height: 1),

                const SizedBox(height: CinephileTheme.spacingStackLg),

                // Filmography header
                Row(
                  children: [
                    Text(
                      'Filmography',
                      style: CinephileTheme.headlineLg(
                        color: CinephileTheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CinephileTheme.primaryContainer.withAlpha(20),
                        borderRadius:
                            BorderRadius.circular(CinephileTheme.radiusXxl),
                        border: Border.all(
                          color: CinephileTheme.primaryContainer.withAlpha(50),
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
                const SizedBox(height: CinephileTheme.spacingStackSm),
              ],
            ),
          ),
        ),

        // ── Filmography Grid ───────────────────────────────────────────
        if (movies.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => MovieCard(movie: movies[index]),
                childCount: movies.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.55,
                crossAxisSpacing: CinephileTheme.spacingGutter,
                mainAxisSpacing: CinephileTheme.spacingStackMd,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
              ),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: CinephileTheme.surfaceContainer,
                  borderRadius:
                      BorderRadius.circular(CinephileTheme.radiusLg),
                  border: Border.all(color: Colors.white.withAlpha(10)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.movie_filter_outlined,
                      size: 40,
                      color:
                          CinephileTheme.onSurfaceVariant.withAlpha(100),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No movies found for this actor.',
                      style: CinephileTheme.bodyMd(
                        color: CinephileTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: CinephileTheme.spacingStackLg),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _backButton() {
    return Padding(
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
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(26)),
        color: Colors.white.withAlpha(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CinephileTheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CinephileTheme.labelSm(
                color: CinephileTheme.onSurfaceVariant,
              ).copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private Data Bundle ──────────────────────────────────────────────────────

class _ActorData {
  final ActorDetail detail;
  final List<Movie> movies;

  const _ActorData({required this.detail, required this.movies});
}
