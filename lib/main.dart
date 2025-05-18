import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'viewmodels/home_viewmodel.dart';
import 'services/tmdb_api_service.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Increase timeout for all HTTP connections
    HttpClient().connectionTimeout = const Duration(seconds: 60);

    // Load env variables - don't fail if .env file is missing
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('Warning: Failed to load .env file: $e');
      // Set default API key if env file is missing
      dotenv.env['TMDB_API_KEY'] = '3e994b6758e86784b84fd839cc2e20cb';
    }

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Run the app with simplified initialization
    runApp(const MovieVerseApp());
  } catch (e) {
    print('Error initializing app: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieVerse - Error',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'There was a problem starting the app. Please check your internet connection and restart.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Attempt to restart the app
                    main();
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MovieVerseApp extends StatelessWidget {
  const MovieVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Initialize HomeViewModel lazily when needed and maintain instance
        ChangeNotifierProxyProvider<AuthService, HomeViewModel>(
          create: (_) => HomeViewModel(TmdbApiService()),
          update: (_, auth, previousViewModel) {
            // Keep the previous view model instance to avoid state rebuilds
            return previousViewModel ?? HomeViewModel(TmdbApiService());
          },
        ),
      ],
      child: MaterialApp(
        title: 'MovieVerse',
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    print("AuthGate build called with user: ${auth.currentUser?.uid}");

    // Set persistence only for web platform
    Future.microtask(() {
      try {
        // Only call setPersistence on web platforms
        if (kIsWeb) {
          FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
        }
      } catch (e) {
        print('Failed to set persistence: $e');
      }
    });

    return StreamBuilder<User?>(
      stream: auth.userChanges,
      builder: (context, snapshot) {
        print(
            "AuthGate StreamBuilder update: connection=${snapshot.connectionState}, hasData=${snapshot.hasData}, user=${snapshot.data?.uid}");

        // Show loading indicator while authentication state is determined
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check for auth errors
        if (snapshot.hasError) {
          print('Auth state error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Authentication Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      auth.signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Return a Builder to delay HomeScreen creation until after Provider is updated
          return Builder(builder: (context) {
            print("Building HomeScreen for user: ${snapshot.data?.uid}");
            return HomeScreen(key: ValueKey(snapshot.data?.uid));
          });
        }
        // User is not logged in
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
