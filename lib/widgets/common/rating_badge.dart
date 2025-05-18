import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// A reusable rating badge widget that displays a movie rating
class RatingBadge extends StatelessWidget {
  final double rating;
  final double size;

  /// Creates a rating badge with the given [rating]
  /// [size] controls the overall size of the badge (default: medium)
  const RatingBadge({
    super.key,
    required this.rating,
    this.size = RatingBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine icon and text size based on badge size
    final iconSize = size == RatingBadgeSize.small
        ? 12.0
        : size == RatingBadgeSize.medium
            ? 16.0
            : 20.0;

    final fontSize = size == RatingBadgeSize.small
        ? 10.0
        : size == RatingBadgeSize.medium
            ? 12.0
            : 14.0;

    final horizontalPadding = size == RatingBadgeSize.small
        ? 6.0
        : size == RatingBadgeSize.medium
            ? 8.0
            : 12.0;

    final verticalPadding = size == RatingBadgeSize.small
        ? 2.0
        : size == RatingBadgeSize.medium
            ? 4.0
            : 6.0;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: iconSize,
          ),
          SizedBox(width: size == RatingBadgeSize.small ? 2 : 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard sizes for the rating badge
class RatingBadgeSize {
  static const double small = 0.75;
  static const double medium = 1.0;
  static const double large = 1.5;
}
