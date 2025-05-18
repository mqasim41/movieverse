import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  Future<void> _submitForm(AuthService auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // The auth state change listener in AuthGate will handle navigation
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
      print('Firebase login error: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
      print('Generic login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid login credentials.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> _signInWithGoogle(AuthService auth) async {
    // Check mounted before starting
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await auth.signInWithGoogle();

      // Only update state if widget is still mounted AND result is null (user cancelled)
      // If sign-in was successful, Firebase will redirect
      if (result == null && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Don't set state after successful login as the auth listener will trigger navigation
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
          _isLoading = false; // Reset loading state here too
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google sign-in failed: ${e.toString()}';
          _isLoading = false; // Reset loading state here too
        });

        // Show more detailed error in console for debugging
        print('Google sign-in error: $e');
      }
    }
    // Remove finally block since loading state is now handled in each case
  }

  // Add this debug method
  Future<void> _testGoogleSignIn(AuthService auth) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await auth.testGoogleSignInConfig();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = result
              ? 'Google Sign-In configuration test PASSED'
              : 'Google Sign-In configuration test FAILED but no error. Check console logs.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google Sign-In test error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.primaryDarkColor.withOpacity(0.7),
              AppTheme.secondaryDarkColor.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.movie_creation_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    'MovieVerse',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    'Your Universe of Movies',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(AppTheme.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.red.shade800.withOpacity(0.7),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLarge),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLarge),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          enabled: !_isLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sign in button
                        ElevatedButton(
                          onPressed:
                              _isLoading ? null : () => _submitForm(auth),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLarge),
                            ),
                            elevation: AppTheme.elevationMedium,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Register button
                        TextButton(
                          onPressed: _isLoading ? null : _navigateToRegister,
                          child: Text(
                            'New user? Create an account',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google sign in button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login_rounded),
                    label: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'CONTINUE WITH GOOGLE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: AppTheme.elevationLarge,
                      shadowColor: Colors.black45,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusExtraLarge),
                      ),
                    ),
                    onPressed:
                        _isLoading ? null : () => _signInWithGoogle(auth),
                  ),

                  const SizedBox(height: 40),

                  // App version
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),

                  // Debug button - only in debug mode
                  if (kDebugMode)
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => _testGoogleSignIn(auth),
                      child: Text(
                        'Test Google Sign-In Config',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
