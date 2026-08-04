import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/movie_card.dart';

class RecommendedMoviesScreen extends StatefulWidget {
  const RecommendedMoviesScreen({super.key});

  @override
  State<RecommendedMoviesScreen> createState() => _RecommendedMoviesScreenState();
}

class _RecommendedMoviesScreenState extends State<RecommendedMoviesScreen> {
  final ProfileService _profileService = ProfileService();
  final MovieService _movieService = MovieService();

  List<Movie>? _movies;
  bool _isLoading = true;
  String _message = 'Analyzing your taste...';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final ratedList = await _profileService.getRatedMoviesStream().first;
      final highRated = ratedList.where((m) => m.rating >= 7.0).toList();
      
      if (highRated.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = 'Rate some movies highly (7.0+) to get personalized recommendations!';
          });
        }
        return;
      }

      final recentHighRated = highRated.take(5).toList();
      final genreCounts = <int, int>{};
      
      for (var rm in recentHighRated) {
        try {
          final detail = await _movieService.fetchMovieDetails(movieId: rm.movieId);
          for (var genreId in detail.genreIds) {
            genreCounts[genreId] = (genreCounts[genreId] ?? 0) + 1;
          }
        } catch (_) {}
      }

      if (genreCounts.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = 'Not enough genre data to make recommendations.';
          });
        }
        return;
      }

      final topGenreId = genreCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      final recommended = await _movieService.fetchDiscoverMovies(genreIds: [topGenreId]);

      if (mounted) {
        setState(() {
          _movies = recommended;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'Error loading recommendations.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,
      appBar: AppBar(
        backgroundColor: CinephileTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: CinephileTheme.onSurface),
        title: Text(
          'Recommended for You',
          style: CinephileTheme.headlineMd(color: CinephileTheme.onSurface),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: CinephileTheme.primaryContainer))
          : _movies == null || _movies!.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _message,
                      style: CinephileTheme.bodyLg(
                          color: CinephileTheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _movies!.length,
                  itemBuilder: (context, index) {
                    return MovieCard(movie: _movies![index]);
                  },
                ),
    );
  }
}
