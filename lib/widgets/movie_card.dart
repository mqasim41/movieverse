import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';
import '../config/theme.dart';
import 'common/poster_image.dart';
import 'common/rating_badge.dart';
import '../services/firestore_service.dart';
import '../screens/movie_detail_screen.dart';

/// A card that displays movie information in a grid or list
class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool compact;

  /// Creates a card that displays movie information
  /// [compact] determines if this is a smaller version of the card
  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.compact = false,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isFavorite = false;
  bool _isWatched = false;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  String? _previousMovieId;

  @override
  void initState() {
    super.initState();
    _previousMovieId = widget.movie.id.toString();
    _checkIfFavorite();
    _checkIfWatched();
  }

  @override
  void didUpdateWidget(MovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if movie ID changed or if we need to refresh favorite status
    if (oldWidget.movie.id != widget.movie.id) {
      _previousMovieId = widget.movie.id.toString();
      _checkIfFavorite();
      _checkIfWatched();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh favorite status when dependencies change
    // This helps when navigating back from details screen
    _checkIfFavorite();
    _checkIfWatched();
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
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _checkIfWatched() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final isWatched = await _firestoreService.isWatched(
          user.uid, widget.movie.id.toString());

      if (mounted) {
        setState(() {
          _isWatched = isWatched;
        });
      }
    } catch (e) {
      // Silently fail
      print('Error checking watched status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    // Store previous state to revert if operation fails
    final previousState = _isFavorite;

    // Optimistic UI update
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (previousState) {
        // Remove from favorites
        await _firestoreService.removeFromFavorites(
            user.uid, widget.movie.id.toString());
      } else {
        // Add to favorites
        await _firestoreService.addToFavorites(user.uid, widget.movie.toJson());
      }
    } catch (e) {
      // Revert to previous state if operation fails
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    // Use a fixed height container instead of a card with columns
    return Card(
      elevation: AppTheme.elevationMedium,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(2), // Reduce margin to save space
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: InkWell(
        onTap: widget.onTap ??
            () {
              // Navigate to detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(movie: widget.movie),
                ),
              );
            },
        child: LayoutBuilder(builder: (context, constraints) {
          // Calculate available width to set proper height constraints
          final width = constraints.maxWidth;
          final imageHeight = widget.compact
              ? width * (3 / 5) // More compact aspect ratio for recommendations
              : width * (3 / 2); // 2:3 ratio for normal

          // Adjust text section height for compact mode
          final textHeight = widget.compact ? 35.0 : 55.0;

          // Total height of the card
          final totalHeight = imageHeight + textHeight;

          return SizedBox(
            height: totalHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensure column doesn't expand
              children: [
                // Image section - takes imageHeight space
                SizedBox(
                  height: imageHeight,
                  width: width,
                  child: Stack(
                    children: [
                      // Poster image
                      Positioned.fill(
                        child: PosterImage(
                          posterPath: widget.movie.posterPath,
                          showShadow: false,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusLarge),
                            topRight: Radius.circular(AppTheme.radiusLarge),
                          ),
                        ),
                      ),

                      // Watched indicator at bottom left
                      if (user != null && _isWatched)
                        Positioned(
                          bottom: AppTheme.paddingSmall,
                          left: AppTheme.paddingSmall,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: widget.compact
                                ? const Icon(
                                    Icons.visibility,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Watched',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                      // Rating badge at top right
                      Positioned(
                        top: AppTheme.paddingSmall,
                        right: AppTheme.paddingSmall,
                        child: RatingBadge(
                          rating: widget.movie.rating,
                          size: widget.compact
                              ? RatingBadgeSize.small
                              : RatingBadgeSize
                                  .small, // Force small size always
                        ),
                      ),

                      // Favorite button at top left
                      if (user != null)
                        Positioned(
                          top: AppTheme.paddingSmall,
                          left: AppTheme.paddingSmall,
                          child: Material(
                            color: Colors.black.withOpacity(0.5),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: IconButton(
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
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _isFavorite
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                              onPressed: _isLoading ? null : _toggleFavorite,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Title and year - fixed height container with padding reduction
                Container(
                  height: textHeight,
                  width: width,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact
                        ? AppTheme.paddingSmall / 2
                        : AppTheme.paddingMedium,
                    vertical: widget.compact
                        ? AppTheme.paddingSmall / 3
                        : AppTheme.paddingSmall / 2,
                  ),
                  child: widget.movie.releaseYear != null && !widget.compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title with reduced font size
                            Text(
                              widget.movie.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                // Smaller text
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Year with reduced font size
                            Text(
                              widget.movie.releaseYear.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontSize: 10, // Even smaller text for year
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.movie.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              // Smaller text
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
