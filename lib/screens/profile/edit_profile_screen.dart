import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/hey_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _displayNameController;
  late TextEditingController _bioController;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _newPhotoUrl;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _newPhotoUrl = user?.photoUrl;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage(ImageSource source, String uid) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (!await file.exists()) return;

      setState(() => _isUploadingPhoto = true);

      final downloadUrl = await _storageService.uploadProfileImage(
        uid: uid,
        file: file,
      );

      if (mounted) {
        setState(() {
          _newPhotoUrl = downloadUrl;
          _isUploadingPhoto = false;
        });

        // Also persist photoUrl immediately to user profile in Firestore
        await _firestoreService.updateUserProfile(uid, {
          'photoUrl': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(UserModel user) {
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
                  _handlePickImage(ImageSource.gallery, user.uid);
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
                  _handlePickImage(ImageSource.camera, user.uid);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final newName = _displayNameController.text.trim();
    final newBio = _bioController.text.trim();

    setState(() => _isSaving = true);

    try {
      await _firestoreService.updateUserProfile(user.uid, {
        'displayName': newName,
        'bio': newBio,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: HeyTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusSmall)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: HeyTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _handleSaveProfile(user),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: HeyTheme.primary),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: HeyTheme.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with camera change button
              Center(
                child: Stack(
                  children: [
                    HeyAvatar(
                      photoUrl: _newPhotoUrl ?? user.photoUrl,
                      name: _displayNameController.text.isNotEmpty
                          ? _displayNameController.text
                          : user.displayName,
                      radius: 46,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isUploadingPhoto ? null : () => _showImagePickerSheet(user),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: HeyTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? HeyTheme.darkSurface : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isUploadingPhoto ? null : () => _showImagePickerSheet(user),
                child: const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HeyTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Full Name field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _displayNameController,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Display name cannot be empty';
                      }
                      if (val.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      filled: true,
                      fillColor: isDark ? HeyTheme.darkSurface : Colors.white,
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        borderSide: BorderSide(color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        borderSide: BorderSide(color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        borderSide: const BorderSide(color: HeyTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Username field (Locked / Read-Only to preserve username architecture)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'Unique handle',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark ? HeyTheme.darkSurface.withOpacity(0.6) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                      border: Border.all(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alternate_email_rounded,
                          size: 18,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Usernames cannot be changed once created.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bio field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bio',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'Max 160 chars',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 160,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tell the Hey Fans community about yourself...',
                      filled: true,
                      fillColor: isDark ? HeyTheme.darkSurface : Colors.white,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        borderSide: BorderSide(color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        borderSide: BorderSide(color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        borderSide: const BorderSide(color: HeyTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Email Display (Read-Only)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark ? HeyTheme.darkSurface.withOpacity(0.6) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                      border: Border.all(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Save Button
              HeyButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: () => _handleSaveProfile(user),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
