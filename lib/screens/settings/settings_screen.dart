import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/hey_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;

  Future<void> _handleUpdateAvatar(UserModel user) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HeyTheme.radiusMedium)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeyTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: HeyTheme.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick a photo from your album'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processAvatarUpload(user, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeyTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: HeyTheme.secondary),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture using device camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processAvatarUpload(user, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processAvatarUpload(UserModel user, ImageSource source) async {
    if (_isUploadingAvatar) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (!await file.exists()) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final downloadUrl = await _storageService.uploadProfileImage(
        uid: user.uid,
        file: file,
      );

      await _firestoreService.updateUserProfile(user.uid, {
        'photoUrl': downloadUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Hey Fans?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HeyTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Account Summary Card
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                border: Border.all(
                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _isUploadingAvatar ? null : () => _handleUpdateAvatar(user),
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        HeyAvatar(
                          photoUrl: user.photoUrl,
                          name: user.displayName,
                          radius: 28,
                          showPresence: false,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: HeyTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Account Management Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              ),
            ),
          ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            ),
            tileColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HeyTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
              ),
              child: const Icon(Icons.person_outline_rounded, color: HeyTheme.primary, size: 20),
            ),
            title: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Update display name, bio, and avatar'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.editProfile);
            },
          ),
          const SizedBox(height: 16),

          // Privacy & Safety Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SAFETY & PRIVACY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              ),
            ),
          ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            ),
            tileColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HeyTheme.errorRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
              ),
              child: const Icon(Icons.block_rounded, color: HeyTheme.errorRed, size: 20),
            ),
            title: const Text('Blocked Accounts', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Manage accounts you have blocked'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.blockedUsers);
            },
          ),
          const SizedBox(height: 16),

          // App Info
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'APPLICATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              ),
            ),
          ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            ),
            tileColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
            leading: const Icon(Icons.info_outline, color: HeyTheme.primary),
            title: const Text('About Hey Fans'),
            subtitle: const Text('Version 1.0.0 (Safety & Account Controls)'),
          ),
          const SizedBox(height: 12),

          // Logout Action
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            ),
            tileColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
            leading: const Icon(Icons.logout_rounded, color: HeyTheme.errorRed),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: HeyTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Sign out of your account on this device'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
