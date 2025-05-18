import 'package:flutter_test/flutter_test.dart';
import 'package:movieverse/models/movie.dart';

void main() {
  group('Movie Model Tests', () {
    test('should create Movie from JSON correctly', () {
      // Arrange
      final Map<String, dynamic> json = {
        'id': 123,
        'title': 'Test Movie',
        'poster_path': '/test-poster.jpg',
        'vote_average': 8.5,
        'release_date': '2023-05-15',
        'overview': 'This is a test movie description',
      };

      // Act
      final Movie movie = Movie.fromJson(json);

      // Assert
      expect(movie.id, 123);
      expect(movie.title, 'Test Movie');
      expect(movie.posterPath, '/test-poster.jpg');
      expect(movie.rating, 8.5);
      expect(movie.releaseDate, '2023-05-15');
      expect(movie.overview, 'This is a test movie description');
    });

    test('should handle missing or invalid JSON fields', () {
      // Arrange - minimal JSON with missing fields
      final Map<String, dynamic> json = {
        'id': 456,
        'title': 'Minimal Movie',
      };

      // Act
      final Movie movie = Movie.fromJson(json);

      // Assert
      expect(movie.id, 456);
      expect(movie.title, 'Minimal Movie');
      expect(movie.posterPath, '');
      expect(movie.rating, 0.0);
      expect(movie.releaseDate, null);
      expect(movie.overview, null);
    });

    test('should handle completely invalid JSON', () {
      // Arrange - completely invalid JSON
      final Map<String, dynamic> json = {'invalid': 'data'};

      // Act
      final Movie movie = Movie.fromJson(json);

      // Assert
      expect(movie.id, 0);
      expect(movie.title, 'Unknown Title');
      expect(movie.posterPath, '');
      expect(movie.rating, 0.0);
    });

    test('should extract correct release year from date', () {
      // Arrange
      final Movie movie = Movie(
        id: 789,
        title: 'Year Test Movie',
        posterPath: '/poster.jpg',
        rating: 7.0,
        releaseDate: '2021-12-25',
      );

      // Act & Assert
      expect(movie.releaseYear, 2021);
    });

    test('should return null for invalid release date', () {
      // Arrange
      final Movie movie = Movie(
        id: 789,
        title: 'Invalid Date Movie',
        posterPath: '/poster.jpg',
        rating: 7.0,
        releaseDate: 'not-a-date',
      );

      // Act & Assert
      expect(movie.releaseYear, null);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final Movie movie = Movie(
        id: 123,
        title: 'JSON Test Movie',
        posterPath: '/test-poster.jpg',
        rating: 9.0,
        releaseDate: '2022-01-01',
        overview: 'Test overview',
      );

      // Act
      final Map<String, dynamic> json = movie.toJson();

      // Assert
      expect(json['id'], 123);
      expect(json['title'], 'JSON Test Movie');
      expect(json['poster_path'], '/test-poster.jpg');
      expect(json['vote_average'], 9.0);
      expect(json['release_date'], '2022-01-01');
      expect(json['overview'], 'Test overview');
    });
  });
}
