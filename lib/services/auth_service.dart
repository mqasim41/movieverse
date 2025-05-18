import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Request email address and profile info
    scopes: ['email', 'profile'],
    // If you configured a server_client_id in strings.xml, use it
    serverClientId:
        '748227604610-6ph2kn61dkh5j96vluqvkeqlb9sq8ibt.apps.googleusercontent.com',
  );
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _auth.currentUser;

  Stream<User?> get userChanges => _auth.authStateChanges();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      // Debug info
      print('Starting Google Sign-In flow...');

      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In canceled by user');
        _setLoading(false);
        return null; // User canceled the sign-in flow
      }

      print('Google Sign-In successful for: ${googleUser.email}');

      // Obtain auth details from request
      print('Getting Google Auth details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create new credential for firebase
      print('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with credential
      print('Signing into Firebase...');
      try {
        final userCredential = await _auth.signInWithCredential(credential);
        print('Firebase auth successful: ${userCredential.user?.uid}');

        // Initialize user in Firestore if needed
        if (userCredential.user != null) {
          try {
            print('Initializing user profile in Firestore...');
            await _firestoreService.initializeUserProfile(
              userId: userCredential.user!.uid,
              displayName: userCredential.user!.displayName,
              email: userCredential.user!.email,
              photoURL: userCredential.user!.photoURL,
            );
            print('User profile initialized in Firestore');
          } catch (e) {
            // Log error but don't rethrow - auth succeeded
            print('Failed to initialize user profile: $e');
          }
        }

        _setLoading(false);
        return userCredential;
      } catch (e) {
        print('Firebase signInWithCredential error: $e');
        throw e;
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      print('Attempting to sign in with email: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      print('Email sign-in successful for user: ${userCredential.user?.uid}');

      _setLoading(false);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase email sign-in error: ${e.code} - ${e.message}');
      _setLoading(false);
      _setError(e.message);
      rethrow;
    } catch (e) {
      print('Generic email sign-in error: $e');
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      print('Attempting to register with email: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      print(
          'Email registration successful for user: ${userCredential.user?.uid}');

      // Initialize user in Firestore
      if (userCredential.user != null) {
        try {
          await _firestoreService.initializeUserProfile(
            userId: userCredential.user!.uid,
            email: email,
            displayName: null,
            photoURL: null,
          );
          print(
              'User profile initialized in Firestore for: ${userCredential.user!.uid}');
        } catch (e) {
          print('Failed to initialize user profile in Firestore: $e');
          // Don't rethrow here - we still want to return the userCredential
        }
      }

      _setLoading(false);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase registration error: ${e.code} - ${e.message}');
      _setLoading(false);
      _setError(e.message);
      rethrow;
    } catch (e) {
      print('Generic registration error: $e');
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user != null) {
        // Update Firebase Auth profile
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        // Update Firestore profile
        await _firestoreService.updateUserProfile(
          userId: user.uid,
          displayName: displayName,
          photoURL: photoURL,
        );

        // Force refresh to ensure we get the latest user data
        await user.reload();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      // Sign out of Google if signed in with Google
      await _googleSignIn.signOut();
      // Sign out of Firebase
      await _auth.signOut();

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  // Add this method to test Google Sign-In configuration
  Future<bool> testGoogleSignInConfig() async {
    try {
      print('Testing Google Sign-In configuration...');

      // Check if currently signed in
      final isCurrentlySignedIn = await _googleSignIn.isSignedIn();
      print('Currently signed in to Google: $isCurrentlySignedIn');

      if (isCurrentlySignedIn) {
        await _googleSignIn.signOut();
        print('Signed out of Google account');
      }

      // Attempt silent sign in to check configuration
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        print('Silent sign-in worked: ${account.email}');
        return true;
      } else {
        print('Silent sign-in failed, but configuration appears valid');
        return false;
      }
    } catch (e) {
      print('Google Sign-In configuration test failed: $e');
      return false;
    }
  }
}
