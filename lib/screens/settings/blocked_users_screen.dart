import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/safety_dialogs.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: HeyTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Blocked Accounts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<String>>(
        stream: _firestoreService.streamBlockedUserIds(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: HeyTheme.primary));
          }

          final blockedIds = snapshot.data ?? [];

          if (blockedIds.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: HeyTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 36,
                        color: HeyTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Blocked Accounts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accounts you block will appear here. Blocked users cannot message you, see your profile, or invite you to groups.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: blockedIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final blockedUid = blockedIds[index];

              return FutureBuilder<UserModel?>(
                future: _firestoreService.getUser(blockedUid),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;

                  return Container(
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
                          photoUrl: user?.photoUrl,
                          name: user?.displayName ?? 'Blocked User',
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Hey Fan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user != null ? '@${user.username}' : blockedUid,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            if (user != null) {
                              HeySafetyDialogs.showUnblockConfirmationDialog(
                                context,
                                targetUser: user,
                                currentUserId: currentUser.uid,
                              );
                            } else {
                              _firestoreService.unblockUser(
                                currentUserId: currentUser.uid,
                                blockedUserId: blockedUid,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: HeyTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: const Size(60, 32),
                          ),
                          child: const Text(
                            'Unblock',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HeyTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
