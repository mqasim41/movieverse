import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';
import 'tmdb_api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TmdbApiService _tmdbApiService = TmdbApiService();
  late final String _apiKey;

  RecommendationService() {
    // Set the same API key as in TmdbApiService
    _apiKey = dotenv.env['TMDB_API_KEY'] ?? '3e994b6758e86784b84fd839cc2e20cb';
  }

  // Get recommendations based on user's favorite movies
  Future<List<Movie>> getRecommendations(String userId) async {
    // Get user's favorites
    final favorites = await _getFavoritesMovieIds(userId);

    if (favorites.isEmpty) {
      // If user has no favorites, return popular movies
      return await _tmdbApiService.getPopularMovies();
    }

    // Get recommendations based on favorites (up to 3 movies)
    final recommendations = <Movie>[];
    final processedIds = <int>{};

    // Limit to 3 movies to avoid too many API calls
    final moviesToProcess = favorites.take(3).toList();

    for (final movieId in moviesToProcess) {
      final similarMovies = await _getSimilarMovies(int.parse(movieId));

      // Add movies that are not already in recommendations or user's favorites
      for (final movie in similarMovies) {
        if (!processedIds.contains(movie.id) &&
            !favorites.contains(movie.id.toString())) {
          recommendations.add(movie);
          processedIds.add(movie.id);

          // Limit to 10 recommendations
          if (recommendations.length >= 10) break;
        }
      }

      // Break early if we have enough recommendations
      if (recommendations.length >= 10) break;
    }

    return recommendations;
  }

  // Helper method to get similar movies from TMDB API
  Future<List<Movie>> _getSimilarMovies(int movieId) async {
    try {
      final uri = Uri.parse(
          'https://api.themoviedb.org/3/movie/$movieId/similar?api_key=$_apiKey&language=en-US&page=1');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List results = data['results'];
        return results.map((e) => Movie.fromJson(e)).toList();
      } else {
        print('API error: ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching similar movies: $e');
      return [];
    }
  }

  // Get all favorite movie IDs for a user
  Future<List<String>> _getFavoritesMovieIds(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null && userData.containsKey('favorites')) {
        return List<String>.from(userData['favorites']);
      }

      return [];
    } catch (e) {
      print('Error fetching favorite movie IDs: $e');
      return [];
    }
  }
}
