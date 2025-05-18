import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import 'dart:async';
import 'dart:io';

/// A widget for displaying user profile images with robust error handling
class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BoxFit fit;
  final Widget? placeholder;

  const ProfileImage({
    super.key,
    this.imageUrl,
    this.size = 40.0,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If we have no image URL, show placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultAvatar(theme);
    }

    // Print URL for debugging
    print('Loading profile image: $imageUrl');

    // We'll use a circular container in all cases
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 300),
          // Use a long timeout for profile images
          httpHeaders: const {
            'Connection': 'keep-alive',
            'Keep-Alive': 'timeout=60, max=1000'
          },
          // Custom progress indicator while loading
          placeholder: (context, url) =>
              placeholder ??
              Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
          // Error widget if image fails to load
          errorWidget: (context, url, error) {
            // Log the error for debugging
            print('ProfileImage error: $error loading URL: $url');
            return _buildDefaultAvatar(theme);
          },
        ),
      ),
    );
  }

  /// Builds a default avatar with the user's initial or a generic icon
  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.2),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.6, // Scale icon to container
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
