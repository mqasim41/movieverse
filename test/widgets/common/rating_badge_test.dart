import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movieverse/widgets/common/rating_badge.dart';

void main() {
  group('RatingBadge Widget Tests', () {
    testWidgets('should display correct rating text',
        (WidgetTester tester) async {
      // Arrange - rating value
      const rating = 8.5;

      // Act - build widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: rating,
            ),
          ),
        ),
      );

      // Assert - rating should be displayed with 1 decimal place
      expect(find.text('8.5'), findsOneWidget);
    });

    testWidgets('should render star icon', (WidgetTester tester) async {
      // Arrange - any rating
      const rating = 7.0;

      // Act - build widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: rating,
            ),
          ),
        ),
      );

      // Assert - star icon should be displayed
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('should apply small size correctly',
        (WidgetTester tester) async {
      // Arrange - small size rating badge
      const rating = 9.2;

      // Act - build widget with small size
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: rating,
              size: RatingBadgeSize.small,
            ),
          ),
        ),
      );

      // Assert - container with appropriate padding should be present
      final container = tester.widget<Container>(find.byType(Container));
      final padding = container.padding as EdgeInsets;

      // Small size should have specific padding values
      expect(padding.horizontal, 12.0); // 6.0 * 2
      expect(padding.vertical, 4.0); // 2.0 * 2
    });

    testWidgets('should apply medium size correctly',
        (WidgetTester tester) async {
      // Arrange - medium size rating badge
      const rating = 9.2;

      // Act - build widget with medium size (default)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: rating,
            ),
          ),
        ),
      );

      // Assert - container with appropriate padding should be present
      final container = tester.widget<Container>(find.byType(Container));
      final padding = container.padding as EdgeInsets;

      // Medium size should have specific padding values
      expect(padding.horizontal, 16.0); // 8.0 * 2
      expect(padding.vertical, 8.0); // 4.0 * 2
    });

    testWidgets('should apply large size correctly',
        (WidgetTester tester) async {
      // Arrange - large size rating badge
      const rating = 9.2;

      // Act - build widget with large size
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: rating,
              size: RatingBadgeSize.large,
            ),
          ),
        ),
      );

      // Assert - container with appropriate padding should be present
      final container = tester.widget<Container>(find.byType(Container));
      final padding = container.padding as EdgeInsets;

      // Large size should have specific padding values
      expect(padding.horizontal, 24.0); // 12.0 * 2
      expect(padding.vertical, 12.0); // 6.0 * 2
    });

    testWidgets('should round decimal places correctly',
        (WidgetTester tester) async {
      // Arrange - rating with multiple decimal places
      const rating = 7.6789;

      // Act - build widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBadge(
              rating: rating,
            ),
          ),
        ),
      );

      // Assert - rating should be rounded to 1 decimal place
      expect(find.text('7.7'), findsOneWidget);
    });
  });
}
