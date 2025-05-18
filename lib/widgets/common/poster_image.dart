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

  const PosterImage({
    super.key,
    required this.posterPath,
    this.aspectRatio = 2 / 3, // Standard movie poster ratio
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showShadow = false,
  });

  /// Base URL for TMDb poster images - trying larger size first
  static const _baseImageUrl = 'https://image.tmdb.org/t/p/w780';

  /// Fallback to a lower resolution if the w780 fails
  static const _fallbackImageUrl = 'https://image.tmdb.org/t/p/w500';

  /// Second fallback to even lower resolution
  static const _fallbackImageUrl2 = 'https://image.tmdb.org/t/p/w342';

  /// Final fallback to the lowest resolution
  static const _fallbackImageUrl3 = 'https://image.tmdb.org/t/p/w185';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPosterPathValid = posterPath.isNotEmpty;

    // Only attempt to load image if we have a valid path
    if (!isPosterPathValid) {
      return _buildErrorPlaceholder(theme);
    }

    final fullImageUrl = posterPath.startsWith('http')
        ? posterPath
        : '$_baseImageUrl$posterPath';

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
          child: _buildImageWithFallbacks(fullImageUrl, theme),
        ),
      ),
    );
  }

  Widget _buildImageWithFallbacks(String imageUrl, ThemeData theme) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      maxHeightDiskCache: 900,
      memCacheHeight: 900,
      fadeOutDuration: const Duration(milliseconds: 300),
      fadeInDuration: const Duration(milliseconds: 300),
      placeholderFadeInDuration: const Duration(milliseconds: 300),
      errorListener: (error) {
        debugPrint('Image loading error: $error for URL: $imageUrl');
      },
      placeholder: (_, __) => Container(
        color: theme.colorScheme.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        // Try first fallback if using w780
        if (url.contains('w780') && !posterPath.startsWith('http')) {
          final fallbackUrl = '$_fallbackImageUrl$posterPath';
          return _buildFallbackImage(fallbackUrl, theme);
        }
        // Try second fallback if using w500
        else if (url.contains('w500') && !posterPath.startsWith('http')) {
          final fallbackUrl = '$_fallbackImageUrl2$posterPath';
          return _buildFallbackImage(fallbackUrl, theme);
        }
        // Try final fallback if using w342
        else if (url.contains('w342') && !posterPath.startsWith('http')) {
          final fallbackUrl = '$_fallbackImageUrl3$posterPath';
          return _buildFallbackImage(fallbackUrl, theme);
        }
        return _buildErrorPlaceholder(theme);
      },
    );
  }

  Widget _buildFallbackImage(String imageUrl, ThemeData theme) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      fadeOutDuration: const Duration(milliseconds: 300),
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (_, __) => Container(
        color: theme.colorScheme.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (_, __, ___) => _buildErrorPlaceholder(theme),
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
              Icons.broken_image_rounded,
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
