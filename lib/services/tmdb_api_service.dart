import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbApiService {
  final _baseUrl = 'https://api.themoviedb.org/3';
  late final String _apiKey;

  TmdbApiService() {
    // Try to get API key from env, or use a default for development
    _apiKey = dotenv.env['TMDB_API_KEY'] ?? '3e994b6758e86784b84fd839cc2e20cb';
  }

  // Get popular movies
  Future<List<Movie>> getPopularMovies() async {
    final uri = Uri.parse(
        '$_baseUrl/movie/popular?api_key=$_apiKey&language=en-US&page=1');
    return _fetchMovies(uri);
  }

  // Search movies by query
  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse(
        '$_baseUrl/search/movie?api_key=$_apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1');
    return _fetchMovies(uri);
  }

  // Get movie details by ID
  Future<Movie> getMovieDetails(int id) async {
    final uri =
        Uri.parse('$_baseUrl/movie/$id?api_key=$_apiKey&language=en-US');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return Movie.fromJson(data);
    } else {
      throw Exception('Failed to fetch movie details: ${response.statusCode}');
    }
  }

  // Helper method to fetch movies from a URI
  Future<List<Movie>> _fetchMovies(Uri uri) async {
    try {
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
      print('Error fetching movies: $e');
      return [];
    }
  }
}
