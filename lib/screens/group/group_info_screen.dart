import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../models/group_member_model.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/hey_button.dart';
import '../profile/user_profile_modal.dart';
import 'invite_members_modal.dart';

class GroupInfoScreen extends StatefulWidget {
  final GroupModel group;
  final UserModel currentUser;
  final List<UserModel> friends;

  const GroupInfoScreen({
    super.key,
    required this.group,
    required this.currentUser,
    this.friends = const [],
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  late GroupModel _currentGroup;
  bool _isUpdating = false;

  void _changeGroupPhoto() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final file = File(picked.path);
      if (!await file.exists()) return;

      setState(() {
        _isUpdating = true;
      });

      final downloadUrl = await _storageService.uploadGroupPhoto(
        groupId: _currentGroup.id,
        file: file,
      );

      await _firestoreService.updateGroupDetails(
        groupId: _currentGroup.id,
        adminUid: widget.currentUser.uid,
        photoUrl: downloadUrl,
      );

      setState(() {
        _currentGroup = GroupModel(
          id: _currentGroup.id,
          name: _currentGroup.name,
          description: _currentGroup.description,
          photoUrl: downloadUrl,
          createdBy: _currentGroup.createdBy,
          createdAt: _currentGroup.createdAt,
          updatedAt: DateTime.now(),
          activeMemberIds: _currentGroup.activeMemberIds,
          memberCount: _currentGroup.memberCount,
          status: _currentGroup.status,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group photo updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update group photo: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
  }

  void _editGroupName() {
    final controller = TextEditingController(text: _currentGroup.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusMedium)),
        title: Text(
          'Edit Group Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary),
          decoration: InputDecoration(
            hintText: 'Group Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusSmall)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await _firestoreService.updateGroupDetails(
                  groupId: _currentGroup.id,
                  adminUid: widget.currentUser.uid,
                  name: newName,
                );
                setState(() {
                  _currentGroup = GroupModel(
                    id: _currentGroup.id,
                    name: newName,
                    description: _currentGroup.description,
                    photoUrl: _currentGroup.photoUrl,
                    createdBy: _currentGroup.createdBy,
                    createdAt: _currentGroup.createdAt,
                    updatedAt: DateTime.now(),
                    activeMemberIds: _currentGroup.activeMemberIds,
                    memberCount: _currentGroup.memberCount,
                    status: _currentGroup.status,
                  );
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: HeyTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editGroupDescription() {
    final controller = TextEditingController(text: _currentGroup.description ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusMedium)),
        title: Text(
          'Edit Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary),
          decoration: InputDecoration(
            hintText: 'About this group circle...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusSmall)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDesc = controller.text.trim();
              Navigator.pop(ctx);
              await _firestoreService.updateGroupDetails(
                groupId: _currentGroup.id,
                adminUid: widget.currentUser.uid,
                description: newDesc,
              );
              setState(() {
                _currentGroup = GroupModel(
                  id: _currentGroup.id,
                  name: _currentGroup.name,
                  description: newDesc,
                  photoUrl: _currentGroup.photoUrl,
                  createdBy: _currentGroup.createdBy,
                  createdAt: _currentGroup.createdAt,
                  updatedAt: DateTime.now(),
                  activeMemberIds: _currentGroup.activeMemberIds,
                  memberCount: _currentGroup.memberCount,
                  status: _currentGroup.status,
                );
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: HeyTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editMyNickname(GroupMemberModel myMemberDoc) {
    final controller = TextEditingController(text: myMemberDoc.nickname ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusMedium)),
        title: Text(
          'My Group Nickname',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a custom nickname for "${_currentGroup.name}". This will not change your global username (@${widget.currentUser.username}).',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary),
              decoration: InputDecoration(
                hintText: 'Enter group nickname...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusSmall)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNick = controller.text.trim();
              Navigator.pop(ctx);
              await _firestoreService.updateMemberNickname(
                groupId: _currentGroup.id,
                uid: widget.currentUser.uid,
                nickname: newNick,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newNick.isEmpty ? 'Group nickname reset to default' : 'Group nickname updated to "$newNick"!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: HeyTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(GroupMemberModel targetMember, GroupMemberModel currentMember) {
    if (targetMember.uid == currentMember.uid) {
      _editMyNickname(currentMember);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(HeyTheme.radiusLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                HeyAvatar(photoUrl: targetMember.photoUrl, name: targetMember.displayName, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetMember.effectiveName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Role: ${targetMember.role.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HeyTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Admin Options
            if (currentMember.isAdmin) ...[
              if (!targetMember.isAdmin)
                ListTile(
                  leading: const Icon(Icons.shield_rounded, color: HeyTheme.primary),
                  title: const Text('Promote to Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _firestoreService.updateMemberRole(
                      groupId: _currentGroup.id,
                      targetUid: targetMember.uid,
                      newRole: 'admin',
                      currentAdminUid: currentMember.uid,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${targetMember.effectiveName} is now an Admin'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              if (!targetMember.isModerator && !targetMember.isAdmin)
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: HeyTheme.warningOrange),
                  title: const Text('Promote to Moderator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _firestoreService.updateMemberRole(
                      groupId: _currentGroup.id,
                      targetUid: targetMember.uid,
                      newRole: 'moderator',
                      currentAdminUid: currentMember.uid,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${targetMember.effectiveName} is now a Moderator'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              if (targetMember.isModerator || targetMember.isAdmin)
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: HeyTheme.primaryDark),
                  title: const Text('Demote to Member', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _firestoreService.updateMemberRole(
                      groupId: _currentGroup.id,
                      targetUid: targetMember.uid,
                      newRole: 'member',
                      currentAdminUid: currentMember.uid,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${targetMember.effectiveName} role changed to Member'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person_remove_rounded, color: HeyTheme.errorRed),
                title: const Text('Remove from Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HeyTheme.errorRed)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _firestoreService.removeMember(
                    groupId: _currentGroup.id,
                    targetUid: targetMember.uid,
                    removerUid: currentMember.uid,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${targetMember.effectiveName} removed from group'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ]
            // Moderator Options
            else if (currentMember.isModerator && targetMember.isRegularMember) ...[
              ListTile(
                leading: const Icon(Icons.person_remove_rounded, color: HeyTheme.errorRed),
                title: const Text('Remove Member', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HeyTheme.errorRed)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _firestoreService.removeMember(
                    groupId: _currentGroup.id,
                    targetUid: targetMember.uid,
                    removerUid: currentMember.uid,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${targetMember.effectiveName} removed from group'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: HeyTheme.primary),
                title: Text('View @${targetMember.username ?? targetMember.displayName} Profile', style: const TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final user = await _firestoreService.getUser(targetMember.uid) ??
                      UserModel(
                        uid: targetMember.uid,
                        email: '',
                        username: targetMember.username ?? targetMember.displayName.toLowerCase().replaceAll(' ', '_'),
                        displayName: targetMember.displayName,
                        photoUrl: targetMember.photoUrl,
                        createdAt: DateTime.now(),
                        lastActive: DateTime.now(),
                      );
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => UserProfileModal(user: user),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _leaveGroup() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusMedium)),
        title: const Text('Leave Group Circle?'),
        content: const Text('You will no longer receive messages from this group. Historical messages will remain preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: HeyTheme.errorRed),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.leaveGroup(
        groupId: _currentGroup.id,
        uid: widget.currentUser.uid,
      );
      if (mounted) {
        // Pop group info and chat screen
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You left "${_currentGroup.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _closeGroup() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusMedium)),
        title: const Text('Close Group Circle?'),
        content: const Text('This will close the group for all members. This action is performed by group Admins.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: HeyTheme.errorRed),
            child: const Text('Close Group', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.closeGroup(
        groupId: _currentGroup.id,
        adminUid: widget.currentUser.uid,
      );
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "${_currentGroup.name}" has been closed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<GroupModel?>(
      stream: _firestoreService.streamGroup(_currentGroup.id),
      builder: (context, groupSnapshot) {
        final group = groupSnapshot.data ?? _currentGroup;

        return StreamBuilder<List<GroupMemberModel>>(
          stream: _firestoreService.streamGroupMembers(group.id),
          builder: (context, membersSnapshot) {
            final members = membersSnapshot.data ?? [];
            final currentMember = members.firstWhere(
              (m) => m.uid == widget.currentUser.uid,
              orElse: () => GroupMemberModel(
                uid: widget.currentUser.uid,
                groupId: group.id,
                displayName: widget.currentUser.displayName,
                username: widget.currentUser.username,
                role: group.createdBy == widget.currentUser.uid ? 'admin' : 'member',
                joinedAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return Scaffold(
              backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
              appBar: AppBar(
                title: const Text('Group Information'),
                actions: [
                  if (currentMember.isAdmin || currentMember.isModerator)
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      tooltip: 'Invite Members',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => InviteMembersModal(
                            group: group,
                            currentUser: widget.currentUser,
                            friends: widget.friends,
                          ),
                        );
                      },
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Group Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                      border: Border.all(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: InkWell(
                            onTap: currentMember.isAdmin && !_isUpdating ? _changeGroupPhoto : null,
                            borderRadius: BorderRadius.circular(36),
                            child: Stack(
                              children: [
                                HeyAvatar(
                                  photoUrl: group.photoUrl,
                                  name: group.name,
                                  radius: 36,
                                ),
                                if (currentMember.isAdmin)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: HeyTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isUpdating
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                              ),
                            ),
                            if (currentMember.isAdmin)
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 16, color: HeyTheme.primary),
                                onPressed: _editGroupName,
                              ),
                          ],
                        ),
                        if (group.description != null && group.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            group.description!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                        if (currentMember.isAdmin && (group.description == null || group.description!.isEmpty))
                          TextButton.icon(
                            onPressed: _editGroupDescription,
                            icon: const Icon(Icons.add_rounded, size: 14),
                            label: const Text('Add group description', style: TextStyle(fontSize: 12)),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: HeyTheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(HeyTheme.radiusPill),
                          ),
                          child: Text(
                            '${group.memberCount} Active ${group.memberCount == 1 ? 'Member' : 'Members'}',
                            style: const TextStyle(
                              color: HeyTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // My Group Profile & Nickname Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                      border: Border.all(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        HeyAvatar(
                          photoUrl: widget.currentUser.photoUrl,
                          name: widget.currentUser.displayName,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currentMember.effectiveName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: currentMember.isAdmin
                                          ? HeyTheme.primary.withAlpha(25)
                                          : (currentMember.isModerator
                                              ? HeyTheme.warningOrange.withAlpha(25)
                                              : Colors.grey.withAlpha(25)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      currentMember.role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: currentMember.isAdmin
                                            ? HeyTheme.primary
                                            : (currentMember.isModerator ? HeyTheme.warningOrange : Colors.grey),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentMember.nickname != null
                                    ? 'Nickname in group • Real name: ${widget.currentUser.displayName}'
                                    : 'Using real name • Tap edit to set group nickname',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: HeyTheme.primary),
                          tooltip: 'Edit Group Nickname',
                          onPressed: () => _editMyNickname(currentMember),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Members Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GROUP MEMBERS (${members.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: HeyTheme.primary,
                        ),
                      ),
                      if (currentMember.isAdmin || currentMember.isModerator)
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => InviteMembersModal(
                                group: group,
                                currentUser: widget.currentUser,
                                friends: widget.friends,
                              ),
                            );
                          },
                          child: const Text(
                            '+ Invite Member',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: HeyTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Members List
                  ...members.map((member) {
                    final isMe = member.uid == widget.currentUser.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _showMemberOptions(member, currentMember),
                        borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                            borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                            border: Border.all(
                              color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              HeyAvatar(
                                photoUrl: member.photoUrl,
                                name: member.displayName,
                                radius: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          member.effectiveName,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Text('(You)', style: TextStyle(fontSize: 11, color: HeyTheme.primary, fontWeight: FontWeight.bold)),
                                        ],
                                      ],
                                    ),
                                    if (member.username != null)
                                      Text(
                                        '@${member.username}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: member.isAdmin
                                      ? HeyTheme.primary.withAlpha(20)
                                      : (member.isModerator
                                          ? HeyTheme.warningOrange.withAlpha(20)
                                          : (isDark ? Colors.white10 : Colors.black.withAlpha(10))),
                                  borderRadius: BorderRadius.circular(HeyTheme.radiusPill),
                                ),
                                child: Text(
                                  member.role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: member.isAdmin
                                        ? HeyTheme.primary
                                        : (member.isModerator ? HeyTheme.warningOrange : (isDark ? Colors.white70 : Colors.black87)),
                                  ),
                                ),
                              ),
                              if (currentMember.isAdmin || (currentMember.isModerator && member.isRegularMember))
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.more_vert_rounded, size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Actions Section
                  HeyButton(
                    text: 'Leave Group Circle',
                    icon: Icons.exit_to_app_rounded,
                    backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                    textColor: HeyTheme.errorRed,
                    borderColor: HeyTheme.errorRed.withAlpha(60),
                    onPressed: _leaveGroup,
                  ),

                  if (currentMember.isAdmin) ...[
                    const SizedBox(height: 10),
                    HeyButton(
                      text: 'Close Group (Admin Only)',
                      icon: Icons.delete_outline_rounded,
                      backgroundColor: Colors.transparent,
                      textColor: HeyTheme.errorRed,
                      onPressed: _closeGroup,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
