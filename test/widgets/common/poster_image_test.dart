import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movieverse/widgets/common/poster_image.dart';

void main() {
  group('PosterImage Widget Tests', () {
    testWidgets('should render with valid posterPath',
        (WidgetTester tester) async {
      // Arrange - valid path
      const posterPath = '/valid-path.jpg';

      // Act - build widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterImage(
              posterPath: posterPath,
            ),
          ),
        ),
      );

      // Assert - cached network image should be rendered
      expect(find.byType(PosterImage), findsOneWidget);
    });

    testWidgets('should show error placeholder with empty posterPath',
        (WidgetTester tester) async {
      // Arrange - empty path
      const posterPath = '';

      // Act - build widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterImage(
              posterPath: posterPath,
            ),
          ),
        ),
      );

      // Assert - error placeholder should be shown
      expect(find.text('No Image'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('should apply custom borderRadius when provided',
        (WidgetTester tester) async {
      // Arrange - custom border radius
      const posterPath = '/valid-path.jpg';
      const customRadius = 30.0;

      // Act - build widget with custom border radius
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterImage(
              posterPath: posterPath,
              borderRadius: BorderRadius.all(Radius.circular(customRadius)),
            ),
          ),
        ),
      );

      // Assert - widget should be created with custom border radius
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should apply shadow when showShadow is true',
        (WidgetTester tester) async {
      // Arrange - with shadow
      const posterPath = '/valid-path.jpg';

      // Act - build widget with shadow
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterImage(
              posterPath: posterPath,
              showShadow: true,
            ),
          ),
        ),
      );

      // Assert - container with shadow decoration should be present
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isNotNull);
    });

    testWidgets('should use correct aspect ratio', (WidgetTester tester) async {
      // Arrange - custom aspect ratio
      const posterPath = '/valid-path.jpg';
      const customAspectRatio = 16.0 / 9.0;

      // Act - build widget with custom aspect ratio
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterImage(
              posterPath: posterPath,
              aspectRatio: customAspectRatio,
            ),
          ),
        ),
      );

      // Assert - aspect ratio should be applied
      final aspectRatioWidget =
          tester.widget<AspectRatio>(find.byType(AspectRatio).first);
      expect(aspectRatioWidget.aspectRatio, customAspectRatio);
    });
  });
}
