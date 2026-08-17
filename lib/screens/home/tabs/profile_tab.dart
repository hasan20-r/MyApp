import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/hey_avatar.dart';
import '../../../widgets/hey_image_viewer.dart';
import '../../../widgets/hey_notification_button.dart';
import '../../profile/user_list_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  String _formatJoinedDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  void _handleShareProfile(BuildContext context, String username) {
    Clipboard.setData(ClipboardData(text: 'https://heyfans.app/u/@$username'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your profile link @$username copied to clipboard!'),
        backgroundColor: HeyTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusSmall)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          const HeyNotificationButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  Center(
                    child: InkWell(
                      onTap: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                          ? () {
                              HeyImageViewer.show(
                                context,
                                imageUrl: user.photoUrl!,
                                title: '@${user.username}',
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(46),
                      child: HeyAvatar(
                        photoUrl: user.photoUrl,
                        name: user.displayName,
                        radius: 46,
                        isOnline: true,
                        showPresence: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HeyTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatJoinedDate(user.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      user.bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Stats Row (Friends, Followers, Following)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                      border: Border.all(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Friends', user.friendsCount, isDark, onTap: () {
                          // Tap Friends
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListScreen(
                                title: 'Mutual Friends',
                                currentUserId: user.uid,
                                targetUserId: user.uid,
                                mode: 'friends',
                              ),
                            ),
                          );
                        }),
                        Container(height: 24, width: 1, color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                        _buildStatItem('Followers', user.followersCount, isDark, onTap: () {
                          // Tap Followers
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListScreen(
                                title: 'Followers',
                                currentUserId: user.uid,
                                targetUserId: user.uid,
                                mode: 'followers',
                              ),
                            ),
                          );
                        }),
                        Container(height: 24, width: 1, color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                        _buildStatItem('Following', user.followingCount, isDark, onTap: () {
                          // Tap Following
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListScreen(
                                title: 'Following',
                                currentUserId: user.uid,
                                targetUserId: user.uid,
                                mode: 'following',
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions: Edit Profile & Share Profile
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HeyTheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _handleShareProfile(context, user.username),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                          side: BorderSide(
                            color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                            width: 1.2,
                          ),
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                          ),
                        ),
                        child: const Icon(Icons.share_outlined, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, int value, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
