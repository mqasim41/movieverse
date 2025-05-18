import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// A reusable widget for displaying movie poster images with consistent styling
/// and placeholder/error handling
class PosterImage extends StatelessWidget {
  final String posterPath;
  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showShadow;
  final bool highQuality;

  const PosterImage({
    super.key,
    required this.posterPath,
    this.aspectRatio = 2 / 3, // Standard movie poster ratio
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showShadow = false,
    this.highQuality = false, // Default to lower quality for faster loading
  });

  // TMDb image URL base
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get appropriate size based on quality needs
    final imageSize = highQuality ? 'w500' : 'w185';

    // Check if we have a valid path to work with
    if (posterPath.isEmpty) {
      return _buildErrorPlaceholder(theme);
    }

    // Construct the full URL - handle both relative paths from API and absolute URLs
    final String imageUrl;
    if (posterPath.startsWith('http')) {
      imageUrl = posterPath;
    } else if (posterPath.startsWith('/')) {
      imageUrl = '$_imageBaseUrl$imageSize$posterPath';
    } else {
      imageUrl = '$_imageBaseUrl$imageSize/$posterPath';
    }

    // For debugging - to see the actual URLs being constructed
    print('Loading image: $imageUrl');

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: showShadow
            ? BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: ClipRRect(
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusLarge),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            placeholder: (context, url) => Container(
              color: theme.colorScheme.surfaceVariant,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              print('Image error: $error for URL: $url');

              // If high quality failed, try with lower quality
              if (highQuality && url.contains('w500')) {
                final fallbackUrl = url.replaceFirst('w500', 'w185');
                print('Trying fallback URL: $fallbackUrl');

                return CachedNetworkImage(
                  imageUrl: fallbackUrl,
                  fit: fit,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return _buildErrorPlaceholder(theme);
                  },
                );
              }

              return _buildErrorPlaceholder(theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
