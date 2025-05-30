import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../config/theme.dart';
import '../widgets/common/profile_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  Stream<Map<String, dynamic>?>? _profileStream;
  Stream<int>? _watchHistoryCountStream;
  Stream<int>? _favoritesCountStream;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    // Listen for auth state changes and update streams accordingly
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _initProfileStream();
    });
  }

  void _initProfileStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileStream = _firestoreService.getUserProfileStream(user.uid);
      _watchHistoryCountStream =
          _firestoreService.getWatchHistoryCountStream(user.uid);
      _favoritesCountStream =
          _firestoreService.getFavoritesCountStream(user.uid);
    } else {
      _profileStream = null;
      _watchHistoryCountStream = null;
      _favoritesCountStream = null;
    }

    // Force refresh UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _signOut(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthService>(context, listen: false).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('You are not logged in'),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _profileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final userProfile = snapshot.data;

        // Get data from Firestore if available, otherwise fallback to Auth data
        final displayName =
            userProfile?['displayName'] ?? user.displayName ?? 'User';
        final email = userProfile?['email'] ?? user.email ?? '';
        final photoURL = userProfile?['photoURL'] ?? user.photoURL;
        final memberSince = userProfile?['createdAt'] != null
            ? ((userProfile!['createdAt'] as Timestamp).toDate())
            : null;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile picture
                ProfileImage(
                  imageUrl: photoURL,
                  size: 100,
                ),

                const SizedBox(height: 16),

                // Display name
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Email
                Text(
                  email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 8),

                // Member since
                if (memberSince != null)
                  Text(
                    'Member since: ${memberSince.day}/${memberSince.month}/${memberSince.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),

                const SizedBox(height: 8),

                // Stats Row
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StreamBuilder<int>(
                        stream: _favoritesCountStream,
                        builder: (context, snapshot) {
                          final favoritesCount = snapshot.data ?? 0;
                          return _buildStatItem(
                            icon: Icons.favorite,
                            label: 'Favorites',
                            value: favoritesCount.toString(),
                            theme: theme,
                            color: Colors.red,
                          );
                        },
                      ),
                      StreamBuilder<int>(
                        stream: _watchHistoryCountStream,
                        builder: (context, snapshot) {
                          final watchedCount = snapshot.data ?? 0;
                          return _buildStatItem(
                            icon: Icons.visibility,
                            label: 'Watched',
                            value: watchedCount.toString(),
                            theme: theme,
                            color: Colors.green,
                          );
                        },
                      ),
                      _buildStatItem(
                        icon: Icons.star,
                        label: 'Ratings',
                        value: '0', // TODO: Implement ratings count
                        theme: theme,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),

                // Email verification status
                if (!user.emailVerified && user.email != null)
                  TextButton.icon(
                    icon: const Icon(Icons.mark_email_unread),
                    label: const Text('Verify Email'),
                    onPressed: () async {
                      try {
                        await user.sendEmailVerification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification email sent'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),

                const Divider(height: 32),

                // Account settings
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Account Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to account settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account settings not implemented yet'),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to change password
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Change password not implemented yet'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('SIGN OUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isLoading ? null : () => _signOut(context),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
