import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/hey_button.dart';
import '../../widgets/hey_text_field.dart';

class CreateGroupDialog extends StatefulWidget {
  final UserModel currentUser;
  final List<UserModel> availableFriends;
  final Function(String groupId)? onGroupCreated;

  const CreateGroupDialog({
    super.key,
    required this.currentUser,
    this.availableFriends = const [],
    this.onGroupCreated,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  final Set<String> _selectedUserUids = {};
  bool _isLoading = false;
  File? _selectedPhotoFile;
  String? _uploadedPhotoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedFriends = widget.availableFriends
          .where((f) => _selectedUserUids.contains(f.uid))
          .toList();

      final groupId = await _firestoreService.createGroup(
        creatorUid: widget.currentUser.uid,
        creatorName: widget.currentUser.displayName,
        creatorUsername: widget.currentUser.username,
        creatorPhotoUrl: widget.currentUser.photoUrl,
        name: name,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        photoUrl: _uploadedPhotoUrl,
        initialInvitees: selectedFriends,
      );

      if (_selectedPhotoFile != null) {
        try {
          final photoUrl = await _storageService.uploadGroupPhoto(
            groupId: groupId,
            file: _selectedPhotoFile!,
          );
          await _firestoreService.updateGroupDetails(
            groupId: groupId,
            adminUid: widget.currentUser.uid,
            photoUrl: photoUrl,
          );
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onGroupCreated?.call(groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$name" created successfully! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(HeyTheme.radiusLarge),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeyTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: HeyTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Group Circle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Connect and chat with multiple fans together',
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
            const SizedBox(height: 20),

            // Group Name
            HeyTextField(
              controller: _nameController,
              label: 'Group Name',
              hint: 'e.g. Anime Fans Club, Gaming Squad',
              prefixIcon: Icons.group_work_rounded,
            ),
            const SizedBox(height: 12),

            // Group Description
            HeyTextField(
              controller: _descController,
              label: 'Description (Optional)',
              hint: 'What is this group circle about?',
              prefixIcon: Icons.info_outline_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Invite Friends Section
            if (widget.availableFriends.isNotEmpty) ...[
              Text(
                'INVITE FRIENDS (${_selectedUserUids.length} selected)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: HeyTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
                  borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                  border: Border.all(
                    color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableFriends.length,
                  itemBuilder: (context, index) {
                    final friend = widget.availableFriends[index];
                    final isSelected = _selectedUserUids.contains(friend.uid);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUserUids.remove(friend.uid);
                          } else {
                            _selectedUserUids.add(friend.uid);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            HeyAvatar(
                              photoUrl: friend.photoUrl,
                              name: friend.displayName,
                              radius: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend.displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    '@${friend.username}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: HeyTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUserUids.add(friend.uid);
                                  } else {
                                    _selectedUserUids.remove(friend.uid);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            HeyButton(
              text: 'Create Group Circle',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isLoading,
              onPressed: _handleCreate,
            ),
          ],
        ),
      ),
    );
  }
}
