import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../models/chat_model.dart';
import '../../../models/group_invitation_model.dart';
import '../../../models/group_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/hey_avatar.dart';
import '../../../widgets/hey_notification_button.dart';
import '../../chat/chat_screen.dart';
import '../../group/create_group_dialog.dart';
import '../../group/group_chat_screen.dart';
import '../../group/group_invitations_modal.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  int _activeSegment = 0; // 0: Direct, 1: Groups

  String _formatChatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat('h:mm a').format(time);
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('E').format(time);
    }
    return DateFormat('MMM d').format(time);
  }

  void _openCreateGroup(BuildContext context, UserModel currentUser, List<UserModel> friends) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGroupDialog(
        currentUser: currentUser,
        availableFriends: friends,
        onGroupCreated: (groupId) async {
          final group = await FirestoreService().getGroup(groupId);
          if (group != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  group: group,
                  currentUser: currentUser,
                  friends: friends,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _openInvitations(BuildContext context, UserModel currentUser, List<UserModel> friends) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupInvitationsModal(
        currentUser: currentUser,
        onGroupJoined: (groupId) async {
          final group = await FirestoreService().getGroup(groupId);
          if (group != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  group: group,
                  currentUser: currentUser,
                  friends: friends,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final firestoreService = FirestoreService();

    final List<UserModel> mockFriends = [
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
        lastSeen: DateTime.now().subtract(const Duration(minutes: 40)),
        createdAt: DateTime(2025, 11, 8),
        updatedAt: DateTime.now(),
      ),
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

    final List<GroupModel> fallbackGroups = [
      GroupModel(
        id: 'group_anime_squad',
        name: 'Anime & Gaming Squad',
        description: 'Official Hey Fans Anime and RPG gaming community',
        createdBy: currentUser?.uid ?? 'user_fan_1',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        activeMemberIds: [currentUser?.uid ?? 'me', 'user_fan_1', 'user_fan_2'],
        memberCount: 3,
        status: 'active',
        lastMessage: 'Super excited for upcoming events and fan discussions! 🍿',
        lastMessageSenderId: 'user_fan_2',
        lastMessageSenderName: 'David K.',
        lastMessageTimestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      GroupModel(
        id: 'group_music_creators',
        name: 'Music Producers & Fans',
        description: 'Vocalists, beatmakers and concert fans discussing new releases',
        createdBy: 'user_friend_1',
        createdAt: DateTime(2026, 1, 20),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        activeMemberIds: [currentUser?.uid ?? 'me', 'user_friend_1'],
        memberCount: 2,
        status: 'active',
        lastMessage: 'Check out the new acoustic sample pack link!',
        lastMessageSenderId: 'user_friend_1',
        lastMessageSenderName: 'Elena Rostova',
        lastMessageTimestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          if (currentUser != null)
            StreamBuilder<List<GroupInvitationModel>>(
              stream: firestoreService.streamUserGroupInvitations(currentUser.uid),
              builder: (context, invSnapshot) {
                final pendingCount = invSnapshot.data?.length ?? 0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mail_outline_rounded),
                      tooltip: 'Group Invitations',
                      onPressed: () => _openInvitations(context, currentUser, mockFriends),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: HeyTheme.accentPink,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$pendingCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const HeyNotificationButton(),
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Create Group Circle',
            onPressed: currentUser == null
                ? null
                : () => _openCreateGroup(context, currentUser, mockFriends),
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Segment Selector (Direct Chats / Group Circles)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                      border: Border.all(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeSegment = 0),
                            borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeSegment == 0
                                    ? HeyTheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: _activeSegment == 0
                                        ? Colors.white
                                        : (isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Direct Chats',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _activeSegment == 0
                                          ? Colors.white
                                          : (isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeSegment = 1),
                            borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeSegment == 1
                                    ? HeyTheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.groups_rounded,
                                    size: 18,
                                    color: _activeSegment == 1
                                        ? Colors.white
                                        : (isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Group Circles',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _activeSegment == 1
                                          ? Colors.white
                                          : (isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content View
                Expanded(
                  child: _activeSegment == 0
                      // Direct 1-to-1 Chats Tab
                      ? StreamBuilder<List<ChatModel>>(
                          stream: firestoreService.streamUserChats(currentUser.uid),
                          builder: (context, snapshot) {
                            return ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              children: [
                                ...mockFriends.map((targetUser) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              targetUser: targetUser,
                                              currentUserId: currentUser.uid,
                                              currentUserName: currentUser.displayName,
                                            ),
                                          ),
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
                                              photoUrl: targetUser.photoUrl,
                                              name: targetUser.displayName,
                                              radius: 22,
                                              isOnline: targetUser.isOnline,
                                              showPresence: true,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        targetUser.displayName,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Active',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '@${targetUser.username} • Direct Message',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
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
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        )
                      // Group Circles Tab
                      : StreamBuilder<List<GroupModel>>(
                          stream: firestoreService.streamUserGroups(currentUser.uid),
                          builder: (context, snapshot) {
                            final groups = (snapshot.hasData && snapshot.data!.isNotEmpty)
                                ? snapshot.data!
                                : fallbackGroups;

                            return ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              children: [
                                // Create Group Action Header
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: HeyTheme.primary.withAlpha(15),
                                    borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                                    border: Border.all(
                                      color: HeyTheme.primary.withAlpha(40),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: HeyTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Create a New Community',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Build fan circles, set roles, and invite friends',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _openCreateGroup(context, currentUser, mockFriends),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: HeyTheme.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Create', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),

                                ...groups.map((group) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GroupChatScreen(
                                              group: group,
                                              currentUser: currentUser,
                                              friends: mockFriends,
                                            ),
                                          ),
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
                                              photoUrl: group.photoUrl,
                                              name: group.name,
                                              radius: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        group.name,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatChatTime(group.lastMessageTimestamp ?? group.updatedAt),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          group.lastMessageSenderName != null
                                                              ? '${group.lastMessageSenderName}: ${group.lastMessage ?? ""}'
                                                              : (group.lastMessage ?? '${group.memberCount} members'),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: HeyTheme.primary.withAlpha(20),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '${group.memberCount}m',
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: HeyTheme.primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
