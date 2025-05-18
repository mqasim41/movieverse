import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // USERS COLLECTION

  // Initialize user document when they register
  Future<void> initializeUserProfile({
    required String userId,
    String? displayName,
    String? email,
    String? photoURL,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'favorites': [],
      'createdAt': FieldValue.serverTimestamp(),
      'lastSignInAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Update user profile data
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoURL,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  // FAVORITES COLLECTION

  // Add movie to favorites
  Future<void> addToFavorites(String userId, Map<String, dynamic> movie) async {
    final movieId = movie['id'].toString();

    // Add to user's favorites array
    await _firestore.collection('users').doc(userId).update({
      'favorites': FieldValue.arrayUnion([movieId])
    });

    // Store movie details in favorites collection
    await _firestore.collection('favorites').doc('$userId-$movieId').set({
      'userId': userId,
      'movieId': movieId,
      'movie': movie,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove movie from favorites
  Future<void> removeFromFavorites(String userId, String movieId) async {
    // Remove from user's favorites array
    await _firestore.collection('users').doc(userId).update({
      'favorites': FieldValue.arrayRemove([movieId])
    });

    // Delete from favorites collection
    await _firestore.collection('favorites').doc('$userId-$movieId').delete();
  }

  // Get user's favorite movies
  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    try {
      // This query requires a composite index to be created
      // If you see a Firestore error about missing index, visit the link in the error message
      // or create an index on "favorites" collection with fields:
      // - userId (Ascending)
      // - addedAt (Descending)
      // - __name__ (Descending)
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['movie'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      // Fallback approach if index is missing
      if (e.toString().contains('FAILED_PRECONDITION') ||
          e.toString().contains('requires an index')) {
        print('Missing Firestore index detected. Using fallback method.');
        print(
            'Please create the required index using the link in the error message.');

        // Fallback: fetch without ordering (will still work, just not sorted)
        final snapshot = await _firestore
            .collection('favorites')
            .where('userId', isEqualTo: userId)
            .get();

        return snapshot.docs
            .map((doc) => doc.data()['movie'] as Map<String, dynamic>)
            .toList();
      } else {
        // Re-throw other errors
        rethrow;
      }
    }
  }

  // Check if a movie is in user's favorites
  Future<bool> isFavorite(String userId, String movieId) async {
    final doc =
        await _firestore.collection('favorites').doc('$userId-$movieId').get();

    return doc.exists;
  }

  // WATCH HISTORY

  // Add movie to watch history
  Future<void> addToWatchHistory(
      String userId, Map<String, dynamic> movie) async {
    final movieId = movie['id'].toString();

    await _firestore.collection('watchHistory').doc('$userId-$movieId').set({
      'userId': userId,
      'movieId': movieId,
      'movie': movie,
      'watchedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user's watch history
  Future<List<Map<String, dynamic>>> getWatchHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('watchHistory')
          .where('userId', isEqualTo: userId)
          .orderBy('watchedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['movie'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      // Fallback if index is missing
      if (e.toString().contains('FAILED_PRECONDITION') ||
          e.toString().contains('requires an index')) {
        // Fetch without ordering
        final snapshot = await _firestore
            .collection('watchHistory')
            .where('userId', isEqualTo: userId)
            .get();

        return snapshot.docs
            .map((doc) => doc.data()['movie'] as Map<String, dynamic>)
            .toList();
      } else {
        rethrow;
      }
    }
  }

  Future<void> saveRating(String uid, int movieId, int rating) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('ratings')
        .doc(movieId.toString())
        .set({'rating': rating, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Stream<int?> getRating(String uid, int movieId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('ratings')
        .doc(movieId.toString())
        .snapshots()
        .map((doc) => doc.exists ? (doc.data()?['rating'] as int?) : null);
  }
}
