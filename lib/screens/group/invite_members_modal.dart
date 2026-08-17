import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/hey_button.dart';

class InviteMembersModal extends StatefulWidget {
  final GroupModel group;
  final UserModel currentUser;
  final List<UserModel> friends;

  const InviteMembersModal({
    super.key,
    required this.group,
    required this.currentUser,
    this.friends = const [],
  });

  @override
  State<InviteMembersModal> createState() => _InviteMembersModalState();
}

class _InviteMembersModalState extends State<InviteMembersModal> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  final Set<String> _invitedUids = {};
  String? _loadingUid;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.friends
        .where((f) => !widget.group.activeMemberIds.contains(f.uid))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _searchResults = widget.friends
            .where((f) => !widget.group.activeMemberIds.contains(f.uid))
            .toList();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _firestoreService.searchUsers(clean);
      if (mounted) {
        setState(() {
          _searchResults = results
              .where((u) => !widget.group.activeMemberIds.contains(u.uid) && u.uid != widget.currentUser.uid)
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _sendInvite(UserModel user) async {
    setState(() {
      _loadingUid = user.uid;
    });

    try {
      await _firestoreService.inviteUserToGroup(
        groupId: widget.group.id,
        groupName: widget.group.name,
        groupPhotoUrl: widget.group.photoUrl,
        inviterUid: widget.currentUser.uid,
        inviterName: widget.currentUser.displayName,
        invitedUid: user.uid,
      );

      if (mounted) {
        setState(() {
          _invitedUids.add(user.uid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${user.displayName}! ✉️'),
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
    } finally {
      if (mounted) {
        setState(() {
          _loadingUid = null;
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
          Text(
            'Invite Fans to ${widget.group.name}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search users or select from your friends',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
              border: Border.all(
                color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search username to invite...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: HeyTheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No eligible fans found to invite.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isInvited = _invitedUids.contains(user.uid);
                          final isBusy = _loadingUid == user.uid;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
                              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                              border: Border.all(
                                color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                HeyAvatar(
                                  photoUrl: user.photoUrl,
                                  name: user.displayName,
                                  radius: 18,
                                  isOnline: user.isOnline,
                                  showPresence: true,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        '@${user.username}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isInvited)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: HeyTheme.successGreen.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_rounded, size: 14, color: HeyTheme.successGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          'Invited',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: HeyTheme.successGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    onPressed: isBusy ? null : () => _sendInvite(user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HeyTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: isBusy
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.send_rounded, size: 13),
                                    label: const Text('Invite', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          HeyButton(
            text: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
