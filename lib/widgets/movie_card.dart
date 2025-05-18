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
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
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

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        // Remove from favorites
        await _firestoreService.removeFromFavorites(
            user.uid, widget.movie.id.toString());
      } else {
        // Add to favorites
        await _firestoreService.addToFavorites(user.uid, widget.movie.toJson());
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
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
              ? width * (9 / 16) // 16:9 ratio for compact
              : width * (3 / 2); // 2:3 ratio for normal

          // Increase text section height to prevent overflow
          final textHeight = widget.compact ? 45.0 : 55.0;

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
                        ? AppTheme.paddingSmall
                        : AppTheme.paddingMedium,
                    vertical:
                        AppTheme.paddingSmall / 2, // Reduce vertical padding
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
