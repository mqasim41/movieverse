import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firestoreService = FirestoreService();
        final profile = await firestoreService.getUserProfile(user.uid);

        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

    if (_isLoading && _userProfile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Get data from Firestore if available, otherwise fallback to Auth data
    final displayName =
        _userProfile?['displayName'] ?? user.displayName ?? 'User';
    final email = _userProfile?['email'] ?? user.email ?? '';
    final photoURL = _userProfile?['photoURL'] ?? user.photoURL;
    final favoritesCount = (_userProfile?['favorites'] as List?)?.length ?? 0;
    final memberSince = _userProfile?['createdAt'] != null
        ? ((_userProfile!['createdAt'] as Timestamp).toDate())
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
                  _buildStatItem(
                    icon: Icons.favorite,
                    label: 'Favorites',
                    value: favoritesCount.toString(),
                    theme: theme,
                  ),
                  _buildStatItem(
                    icon: Icons.history,
                    label: 'Watched',
                    value: '0', // TODO: Implement watch history count
                    theme: theme,
                  ),
                  _buildStatItem(
                    icon: Icons.star,
                    label: 'Ratings',
                    value: '0', // TODO: Implement ratings count
                    theme: theme,
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
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
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
