import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/group_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/hey_avatar.dart';
import '../chat/chat_screen.dart';
import '../group/group_chat_screen.dart';
import '../group/group_invitations_modal.dart';
import '../profile/user_profile_modal.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
    UserModel currentUser,
  ) async {
    // 1. Mark as read immediately
    if (!notification.isRead) {
      await _firestoreService.markNotificationAsRead(
        currentUser.uid,
        notification.id,
      );
    }

    if (!mounted) return;

    // 2. Perform contextual navigation based on notification type
    switch (notification.type) {
      case 'new_follower':
      case 'mutual_friend':
        final targetUid = notification.targetId ?? notification.senderId;
        if (targetUid != null && targetUid.isNotEmpty) {
          _openUserProfile(context, targetUid, currentUser);
        }
        break;

      case 'chat_message':
        final targetUid = notification.targetId ?? notification.senderId;
        if (targetUid != null && targetUid.isNotEmpty) {
          _openChat(context, targetUid, currentUser, notification.chatId);
        }
        break;

      case 'group_invitation':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => GroupInvitationsModal(
            currentUser: currentUser,
            onGroupJoined: (groupId) {
              _openGroup(context, groupId, currentUser);
            },
          ),
        );
        break;

      case 'group_role_change':
        final groupId = notification.groupId;
        if (groupId != null && groupId.isNotEmpty) {
          _openGroup(context, groupId, currentUser);
        }
        break;

      case 'group_member_removed':
        _showRemovalDialog(context, notification);
        break;

      default:
        // Generic tap fallback
        break;
    }
  }

  void _openUserProfile(
    BuildContext context,
    String targetUid,
    UserModel currentUser,
  ) async {
    try {
      final user = await _firestoreService.getUser(targetUid);
      if (user != null && mounted) {
        UserProfileModal.show(context, user: user);
      }
    } catch (_) {}
  }

  void _openChat(
    BuildContext context,
    String targetUid,
    UserModel currentUser,
    String? chatId,
  ) async {
    try {
      final targetUser = await _firestoreService.getUser(targetUid);
      if (targetUser != null && mounted) {
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
      }
    } catch (_) {}
  }

  void _openGroup(
    BuildContext context,
    String groupId,
    UserModel currentUser,
  ) async {
    try {
      final group = await _firestoreService.getGroup(groupId);
      if (group != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              group: group,
              currentUser: currentUser,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  void _showRemovalDialog(BuildContext context, NotificationModel notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: HeyTheme.errorRed, size: 22),
            const SizedBox(width: 8),
            Text(
              notification.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          notification.message,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: HeyTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
        ),
        title: Text(
          'Clear All Activity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all activity notifications? This cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _firestoreService.clearAllNotifications(uid);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All activity notifications cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: HeyTheme.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBadge(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'new_follower':
        icon = Icons.person_add_rounded;
        color = HeyTheme.primary;
        break;
      case 'mutual_friend':
        icon = Icons.favorite_rounded;
        color = HeyTheme.accentPink;
        break;
      case 'chat_message':
        icon = Icons.chat_bubble_rounded;
        color = HeyTheme.primary;
        break;
      case 'group_invitation':
        icon = Icons.mail_rounded;
        color = HeyTheme.warningOrange;
        break;
      case 'group_role_change':
        icon = Icons.verified_user_rounded;
        color = HeyTheme.successGreen;
        break;
      case 'group_member_removed':
        icon = Icons.group_remove_rounded;
        color = HeyTheme.errorRed;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = HeyTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(icon, size: 10, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: HeyTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Activity'),
        actions: [
          StreamBuilder<int>(
            stream: _firestoreService.streamUnreadNotificationsCount(currentUser.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.done_all_rounded, size: 22),
                tooltip: 'Mark all as read',
                onPressed: () {
                  _firestoreService.markAllNotificationsAsRead(currentUser.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All marked as read'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            ),
            color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
            onSelected: (value) {
              if (value == 'mark_read') {
                _firestoreService.markAllNotificationsAsRead(currentUser.uid);
              } else if (value == 'clear_all') {
                _confirmClearAll(context, currentUser.uid);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18, color: HeyTheme.primary),
                    SizedBox(width: 10),
                    Text('Mark all as read', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18, color: HeyTheme.errorRed),
                    SizedBox(width: 10),
                    Text('Clear all activity', style: TextStyle(fontSize: 14, color: HeyTheme.errorRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: HeyTheme.primary,
              indicatorWeight: 3,
              labelColor: HeyTheme.primary,
              unselectedLabelColor: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'All Activity'),
                Tab(text: 'Unread'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _firestoreService.streamNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: HeyTheme.primary),
            );
          }

          final allNotifications = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(
                context,
                allNotifications,
                currentUser,
                isDark,
                emptyTitle: 'No Activity Yet',
                emptySubtitle:
                    'When fans follow you, send messages, or invite you to groups, you will see them here.',
              ),
              _buildNotificationList(
                context,
                allNotifications.where((n) => !n.isRead).toList(),
                currentUser,
                isDark,
                emptyTitle: 'All Caught Up! 🎉',
                emptySubtitle: 'You have no unread notifications.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    List<NotificationModel> notifications,
    UserModel currentUser,
    bool isDark, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (notifications.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  Icons.notifications_none_rounded,
                  size: 36,
                  color: HeyTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
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
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: HeyTheme.errorRed,
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            _firestoreService.deleteNotification(currentUser.uid, notification.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notification dismissed'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          },
          child: InkWell(
            onTap: () => _handleNotificationTap(context, notification, currentUser),
            borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? (isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface)
                    : (isDark
                        ? HeyTheme.primary.withOpacity(0.12)
                        : HeyTheme.primary.withOpacity(0.06)),
                borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                border: Border.all(
                  color: notification.isRead
                      ? (isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder)
                      : HeyTheme.primary.withOpacity(0.3),
                  width: notification.isRead ? 1.0 : 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with Type Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (notification.type.startsWith('group_'))
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                            image: notification.groupPhotoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(notification.groupPhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: notification.groupPhotoUrl == null
                              ? const Center(
                                  child: Icon(Icons.groups_rounded, color: HeyTheme.primary, size: 22),
                                )
                              : null,
                        )
                      else
                        HeyAvatar(
                          photoUrl: notification.senderPhotoUrl,
                          name: notification.senderName ?? 'Hey Fan',
                          radius: 22,
                        ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: _buildActivityBadge(notification.type),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      notification.isRead ? FontWeight.w600 : FontWeight.w700,
                                  color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatNotificationTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Unread Glow Dot Indicator
                  if (!notification.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: HeyTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
