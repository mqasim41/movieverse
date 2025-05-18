import 'package:mocktail/mocktail.dart';
import 'package:movieverse/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {
  final Map<String, bool> _favoritesMap = {};
  final Map<String, Map<String, dynamic>> _moviesMap = {};

  @override
  Future<bool> isFavorite(String userId, String movieId) async {
    return _favoritesMap['$userId-$movieId'] ?? false;
  }

  @override
  Future<void> addToFavorites(String userId, Map<String, dynamic> movie) async {
    final movieId = movie['id'].toString();
    _favoritesMap['$userId-$movieId'] = true;
    _moviesMap['$userId-$movieId'] = movie;
  }

  @override
  Future<void> removeFromFavorites(String userId, String movieId) async {
    _favoritesMap['$userId-$movieId'] = false;
    _moviesMap.remove('$userId-$movieId');
  }

  void setFavoriteStatus(String userId, String movieId, bool isFavorite) {
    _favoritesMap['$userId-$movieId'] = isFavorite;
  }
}
