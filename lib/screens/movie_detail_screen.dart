import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../services/tmdb_api_service.dart';
import '../services/firestore_service.dart';
import '../config/theme.dart';
import '../widgets/common/poster_image.dart';
import '../widgets/common/rating_badge.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final bool fromFavorites;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.fromFavorites = false,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<Movie> _movieFuture;
  bool _isFavorite = false;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  final TmdbApiService _tmdbService = TmdbApiService();

  @override
  void initState() {
    super.initState();
    // Get full movie details from API
    _movieFuture = _tmdbService.getMovieDetails(widget.movie.id);
    _checkIfFavorite();

    // Record this movie in watch history if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.addToWatchHistory(user.uid, widget.movie.toJson());
    }
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final isFavorite = await _firestoreService.isFavorite(
          user.uid, widget.movie.id.toString());

      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Silently fail
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite(Movie movie) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        // Remove from favorites
        await _firestoreService.removeFromFavorites(
            user.uid, movie.id.toString());
      } else {
        // Add to favorites
        await _firestoreService.addToFavorites(user.uid, movie.toJson());
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorites: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
            onPressed: _isLoading ? null : () => _toggleFavorite(widget.movie),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _movieFuture =
                            _tmdbService.getMovieDetails(widget.movie.id);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final movie = snapshot.data ?? widget.movie;

          return CustomScrollView(
            slivers: [
              // Movie poster and basic info
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster image with gradient overlay
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Movie poster
                          PosterImage(
                            posterPath: movie.posterPath,
                            fit: BoxFit.cover,
                            aspectRatio: 16 / 9,
                            borderRadius: BorderRadius.zero,
                          ),

                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  theme.colorScheme.background,
                                ],
                                stops: const [0.7, 1.0],
                              ),
                            ),
                          ),

                          // Rating badge
                          Positioned(
                            top: AppTheme.paddingMedium,
                            right: AppTheme.paddingMedium,
                            child: RatingBadge(
                              rating: movie.rating,
                              size: RatingBadgeSize.large,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title and year
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  movie.title,
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (movie.releaseYear != null)
                                Text(
                                  '(${movie.releaseYear})',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.paddingMedium),

                          // Overview
                          if (movie.overview != null &&
                              movie.overview!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overview',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.paddingSmall),
                                Text(
                                  movie.overview!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
