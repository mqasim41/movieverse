import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/movie.dart';
import '../services/tmdb_api_service.dart';
import '../services/firestore_service.dart';
import '../services/recommendation_service.dart';

class HomeViewModel extends ChangeNotifier {
  final TmdbApiService _apiService;
  final FirestoreService _firestoreService = FirestoreService();
  final RecommendationService _recommendationService = RecommendationService();

  List<Movie> _popular = [];
  List<Movie> _favorites = [];
  List<Movie> _searchResults = [];
  List<Movie> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _favoritesSubscription;

  HomeViewModel(this._apiService) {
    _subscribeToFavorites();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  List<Movie> get popular => _popular;
  List<Movie> get favorites => _favorites;
  List<Movie> get searchResults => _searchResults;
  List<Movie> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _subscribeToFavorites() {
    // Cancel existing subscription if any
    _favoritesSubscription?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (_favorites.isNotEmpty) {
        _favorites = [];
        notifyListeners();
      }
      return;
    }

    // Subscribe to real-time favorites updates
    _favoritesSubscription =
        _firestoreService.getFavoritesStream(user.uid).listen((favoriteMovies) {
      _favorites = favoriteMovies.map((movieData) {
        return Movie.fromJson(movieData);
      }).toList();

      notifyListeners();
    });
  }

  // Load popular movies from API
  Future<void> loadPopular() async {
    _setLoading(true);
    _error = null;

    try {
      final movies = await _apiService.getPopularMovies();
      _popular = movies;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load popular movies: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Legacy method kept for compatibility, now just ensures subscription is active
  Future<void> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (_favorites.isNotEmpty) {
        _favorites = [];
        notifyListeners();
      }
      return;
    }

    // Make sure subscription is active
    if (_favoritesSubscription == null) {
      _subscribeToFavorites();
    }
  }

  // Load movie recommendations based on favorites
  Future<void> loadRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    // If no user is logged in, return popular movies as recommendations
    if (user == null) {
      _recommendations = _popular;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final recommendedMovies =
          await _recommendationService.getRecommendations(user.uid);
      _recommendations = recommendedMovies;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load recommendations: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Search movies by query
  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final movies = await _apiService.searchMovies(query);
      _searchResults = movies;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to search movies: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Toggle favorite status of a movie
  Future<void> toggleFavorite(Movie movie) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isFavorite =
          await _firestoreService.isFavorite(user.uid, movie.id.toString());

      if (isFavorite) {
        // Remove from favorites
        await _firestoreService.removeFromFavorites(
            user.uid, movie.id.toString());
      } else {
        // Add to favorites
        await _firestoreService.addToFavorites(user.uid, movie.toJson());
      }

      // Refresh recommendations when favorites change
      loadRecommendations();
    } catch (e) {
      _error = 'Failed to update favorites: ${e.toString()}';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
