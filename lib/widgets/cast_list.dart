// ---------------------------------------------------------------------------
// cast_list.dart
// ---------------------------------------------------------------------------
// Horizontal scrollable cast list widget that fetches actor data from the
// TMDb `/movie/{movie_id}/credits` endpoint.
//
// States:
//   • Loading  → shimmer skeleton placeholders
//   • Success  → horizontal list of profile cards
//   • Error    → error message with retry button
//   • Empty    → informational "no cast" message
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/cast.dart';
import '../screens/actor/actor_detail_screen.dart';
import '../services/api_exception.dart';
import '../services/movie_service.dart';
import 'shimmer_loading.dart';

class CastList extends StatefulWidget {
  /// The TMDb movie ID to fetch credits for.
  final int movieId;

  const CastList({super.key, required this.movieId});

  @override
  State<CastList> createState() => _CastListState();
}

class _CastListState extends State<CastList> {
  // ── State ────────────────────────────────────────────────────────────────

  late final MovieService _movieService;
  late Future<List<Cast>> _castFuture;

  @override
  void initState() {
    super.initState();
    _movieService = MovieService();
    _castFuture = _fetchCast();
  }

  @override
  void dispose() {
    _movieService.dispose();
    super.dispose();
  }

  Future<List<Cast>> _fetchCast() {
    return _movieService.fetchMovieCredits(movieId: widget.movieId);
  }

  void _retry() {
    setState(() {
      _castFuture = _fetchCast();
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Cast>>(
      future: _castFuture,
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        // ── Error ──
        if (snapshot.hasError) {
          return _buildError(snapshot.error);
        }

        // ── Empty ──
        final cast = snapshot.data;
        if (cast == null || cast.isEmpty) {
          return _buildEmpty();
        }

        // ── Success ──
        return _buildCastList(cast);
      },
    );
  }

  // ── Loading Shimmer ─────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: CinephileTheme.spacingContainerPadding,
        ),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              right: CinephileTheme.spacingStackMd,
            ),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  // Circle avatar shimmer
                  ShimmerLoading(
                    width: 64,
                    height: 64,
                    borderRadius: 32,
                  ),
                  const SizedBox(height: CinephileTheme.spacingBase),
                  // Name shimmer
                  ShimmerLoading(
                    width: 70,
                    height: 12,
                    borderRadius: CinephileTheme.radiusSm,
                  ),
                  const SizedBox(height: 4),
                  // Role shimmer
                  ShimmerLoading(
                    width: 50,
                    height: 10,
                    borderRadius: CinephileTheme.radiusSm,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Error State ─────────────────────────────────────────────────────────

  Widget _buildError(Object? error) {
    final message = error is ApiException
        ? error.message
        : 'Oyuncu bilgileri yüklenemedi.';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CinephileTheme.spacingContainerPadding,
        vertical: CinephileTheme.spacingStackSm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: CinephileTheme.error,
            size: 20,
          ),
          const SizedBox(width: CinephileTheme.spacingBase),
          Expanded(
            child: Text(
              message,
              style: CinephileTheme.labelSm(
                color: CinephileTheme.error,
              ),
            ),
          ),
          const SizedBox(width: CinephileTheme.spacingBase),
          GestureDetector(
            onTap: _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CinephileTheme.radiusXxl),
                border: Border.all(
                  color: CinephileTheme.outlineVariant,
                ),
              ),
              child: Text(
                'Tekrar Dene',
                style: CinephileTheme.labelSm(
                  color: CinephileTheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CinephileTheme.spacingContainerPadding,
        vertical: CinephileTheme.spacingStackSm,
      ),
      child: Text(
        'Bu film için oyuncu bilgisi bulunamadı.',
        style: CinephileTheme.bodyMd(
          color: CinephileTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ── Cast List ───────────────────────────────────────────────────────────

  Widget _buildCastList(List<Cast> cast) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CinephileTheme.spacingContainerPadding,
        ),
        itemCount: cast.length,
        itemBuilder: (context, index) {
          final member = cast[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActorDetailScreen(
                    personId: member.id,
                    actorName: member.name,
                  ),
                ),
              );
            },
            child: _CastCard(cast: member),
          );
        },
      ),
    );
  }
}

// ── Individual Cast Card ──────────────────────────────────────────────────────

class _CastCard extends StatelessWidget {
  final Cast cast;

  const _CastCard({required this.cast});

  @override
  Widget build(BuildContext context) {
    final profileUrl = cast.fullProfileUrl;

    return Padding(
      padding: const EdgeInsets.only(right: CinephileTheme.spacingStackMd),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            // ── Profile Photo ──
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CinephileTheme.outlineVariant.withAlpha(102),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(64),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: profileUrl != null
                  ? Image.network(
                      profileUrl,
                      fit: BoxFit.cover,
                      // Fade-in animation for a polished feel.
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame != null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                      errorBuilder: (_, e, s) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            const SizedBox(height: CinephileTheme.spacingBase),

            // ── Actor Name ──
            Text(
              cast.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CinephileTheme.labelSm(
                color: CinephileTheme.onSurface,
              ),
            ),

            const SizedBox(height: 2),

            // ── Character Name ──
            if (cast.character.isNotEmpty)
              Text(
                cast.character,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CinephileTheme.labelSm(
                  color: CinephileTheme.onSurfaceVariant,
                ).copyWith(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  /// Placeholder icon shown when profile photo is null or fails to load.
  Widget _placeholder() {
    return Container(
      color: CinephileTheme.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: CinephileTheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
