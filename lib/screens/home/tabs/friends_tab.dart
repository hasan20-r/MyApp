import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/user_model.dart';
import '../../../widgets/hey_avatar.dart';
import '../../../widgets/hey_notification_button.dart';
import '../../profile/user_profile_modal.dart';

class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sampleFriends = [
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
      UserModel(
        uid: 'user_friend_2',
        email: 'marcus@heyfans.app',
        displayName: 'Marcus Vance',
        username: 'marcus_v',
        bio: 'Movie critic & Sci-Fi fan 🎬🍿',
        followersCount: 640,
        followingCount: 190,
        friendsCount: 82,
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime(2026, 2, 10),
        updatedAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Mutual Friends'),
        actions: const [
          HeyNotificationButton(),
        ],
      ),
      body: sampleFriends.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 56,
                    color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No mutual friends yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When you and another fan follow each other,\nyou become mutual friends!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: sampleFriends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final friend = sampleFriends[index];
                return InkWell(
                  onTap: () {
                    UserProfileModal.show(
                      context,
                      user: friend,
                      isFollowing: true,
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
                          photoUrl: friend.photoUrl,
                          name: friend.displayName,
                          radius: 22,
                          isOnline: friend.isOnline,
                          showPresence: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                ),
                              ),
                              Text(
                                '@${friend.username}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: HeyTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: HeyTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(HeyTheme.radiusPill),
                          ),
                          child: const Text(
                            'Friends',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HeyTheme.primary,
                            ),
                          ),
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
