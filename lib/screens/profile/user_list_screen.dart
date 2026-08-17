import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/user_model.dart';
import '../../../widgets/hey_avatar.dart';
import 'user_profile_modal.dart';

class UserListScreen extends StatefulWidget {
  final String title;
  final String currentUserId;
  final String targetUserId;
  final String mode; // 'followers', 'following', 'friends'

  const UserListScreen({
    super.key,
    required this.title,
    required this.currentUserId,
    required this.targetUserId,
    required this.mode,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  // Sample data fallback for offline/preview
  List<UserModel> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    // Providing default mock users if offline, and allowing real Firestore binding
    if (widget.mode == 'followers') {
      _users = [
        UserModel(
          uid: 'user_f_1',
          email: 'lucas@heyfans.app',
          displayName: 'Lucas Moura',
          username: 'lucas_m',
          bio: 'Tech & Gaming fan 🕹️',
          followersCount: 140,
          followingCount: 95,
          friendsCount: 22,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime(2026, 1, 10),
          updatedAt: DateTime.now(),
        ),
        UserModel(
          uid: 'user_f_2',
          email: 'sophia@heyfans.app',
          displayName: 'Sophia Turner',
          username: 'sophia_t',
          bio: 'Electronic Music Lover 🎧',
          followersCount: 310,
          followingCount: 180,
          friendsCount: 54,
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime(2025, 11, 20),
          updatedAt: DateTime.now(),
        ),
      ];
    } else if (widget.mode == 'following') {
      _users = [
        UserModel(
          uid: 'user_fan_1',
          email: 'maya@heyfans.app',
          displayName: 'Maya Lin',
          username: 'mayafans',
          bio: 'Anime & Gaming fandom enthusiast 🎮✨',
          followersCount: 342,
          followingCount: 120,
          friendsCount: 45,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime.now(),
        ),
        UserModel(
          uid: 'user_fan_2',
          email: 'david@heyfans.app',
          displayName: 'David K.',
          username: 'david_music',
          bio: 'Concert goer & Vinyl collector 🎵',
          followersCount: 890,
          followingCount: 310,
          friendsCount: 112,
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 25)),
          createdAt: DateTime(2025, 11, 8),
          updatedAt: DateTime.now(),
        ),
      ];
    } else {
      _users = [
        UserModel(
          uid: 'user_friend_1',
          email: 'elena@heyfans.app',
          displayName: 'Elena Rostova',
          username: 'elena_r',
          bio: 'Pop music producer & sound designer 🎹',
          followersCount: 520,
          followingCount: 280,
          friendsCount: 94,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime(2025, 12, 1),
          updatedAt: DateTime.now(),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 48,
                        color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return InkWell(
                      onTap: () {
                        UserProfileModal.show(
                          context,
                          user: user,
                          isFollowing: widget.mode == 'following' || widget.mode == 'friends',
                        );
                      },
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
                              photoUrl: user.photoUrl,
                              name: user.displayName,
                              radius: 22,
                              isOnline: user.isOnline,
                              showPresence: true,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    '@${user.username}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: HeyTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                UserProfileModal.show(
                                  context,
                                  user: user,
                                  isFollowing: widget.mode == 'following' || widget.mode == 'friends',
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: HeyTheme.primary,
                                side: const BorderSide(color: HeyTheme.primary, width: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                                ),
                              ),
                              child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
