import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/hey_image_viewer.dart';
import '../../widgets/safety_dialogs.dart';
import '../chat/chat_screen.dart';

class UserProfileModal extends StatefulWidget {
  final UserModel user;
  final bool isFollowing;
  final VoidCallback? onToggleFollow;
  final VoidCallback? onSendMessage;
  final VoidCallback? onBlockUser;

  const UserProfileModal({
    super.key,
    required this.user,
    this.isFollowing = false,
    this.onToggleFollow,
    this.onSendMessage,
    this.onBlockUser,
  });

  static Future<void> show(
    BuildContext context, {
    required UserModel user,
    bool isFollowing = false,
    VoidCallback? onToggleFollow,
    VoidCallback? onSendMessage,
    VoidCallback? onBlockUser,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserProfileModal(
        user: user,
        isFollowing: isFollowing,
        onToggleFollow: onToggleFollow,
        onSendMessage: onSendMessage,
        onBlockUser: onBlockUser,
      ),
    );
  }

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  final FirestoreService _firestoreService = FirestoreService();
  late bool _isFollowing;
  late int _followersCount;
  bool _isBlocked = false;
  bool _isLoadingBlockState = true;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
    _followersCount = widget.user.followersCount;
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final current = auth.currentUser;
    if (current != null) {
      final blocked = await _firestoreService.isUserBlocked(
        currentUserId: current.uid,
        targetUserId: widget.user.uid,
      );
      if (mounted) {
        setState(() {
          _isBlocked = blocked;
          _isLoadingBlockState = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingBlockState = false);
      }
    }
  }

  void _handleFollowToggle() {
    if (_isBlocked) return;
    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
      if (_followersCount < 0) _followersCount = 0;
    });
    widget.onToggleFollow?.call();
  }

  void _handleShareProfile() {
    Clipboard.setData(ClipboardData(text: 'https://heyfans.app/u/@${widget.user.username}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile link @${widget.user.username} copied to clipboard!'),
        backgroundColor: HeyTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HeyTheme.radiusSmall)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleReportUser() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final current = auth.currentUser;
    if (current == null) return;

    HeySafetyDialogs.showReportDialog(
      context,
      targetUser: widget.user,
      currentUserId: current.uid,
    );
  }

  void _handleToggleBlockUser() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final current = auth.currentUser;
    if (current == null) return;

    if (_isBlocked) {
      HeySafetyDialogs.showUnblockConfirmationDialog(
        context,
        targetUser: widget.user,
        currentUserId: current.uid,
        onUnblocked: () {
          if (mounted) {
            setState(() => _isBlocked = false);
          }
        },
      );
    } else {
      HeySafetyDialogs.showBlockConfirmationDialog(
        context,
        targetUser: widget.user,
        currentUserId: current.uid,
        onBlocked: () {
          if (mounted) {
            setState(() {
              _isBlocked = true;
              _isFollowing = false;
            });
          }
          widget.onBlockUser?.call();
        },
      );
    }
  }

  String _formatJoinedDate(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(HeyTheme.radiusLarge)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Top-Right Actions Header: [X] Close button and [⋮] More Menu button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // [X] Close button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),

                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // [⋮] More/Menu Button
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 22,
                    color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                  ),
                  tooltip: 'More actions',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                  ),
                  color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                  elevation: 8,
                  onSelected: (value) {
                    if (value == 'share') _handleShareProfile();
                    if (value == 'report') _handleReportUser();
                    if (value == 'block') _handleToggleBlockUser();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18, color: HeyTheme.primary),
                          SizedBox(width: 12),
                          Text('Share Profile Link', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Report User', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            _isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                            size: 18,
                            color: _isBlocked ? HeyTheme.primary : HeyTheme.errorRed,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isBlocked ? 'Unblock User' : 'Block User',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _isBlocked ? HeyTheme.primary : HeyTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Avatar
            Center(
              child: InkWell(
                onTap: (widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty)
                    ? () {
                        HeyImageViewer.show(
                          context,
                          imageUrl: widget.user.photoUrl!,
                          title: '@${widget.user.username}',
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(44),
                child: HeyAvatar(
                  photoUrl: widget.user.photoUrl,
                  name: widget.user.displayName,
                  radius: 44,
                  isOnline: widget.user.isOnline,
                  showPresence: true,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Display Name
            Text(
              widget.user.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),

            // Username
            Text(
              '@${widget.user.username}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: HeyTheme.primary,
              ),
            ),

            // Joined Date
            const SizedBox(height: 4),
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
                  _formatJoinedDate(widget.user.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),

            // Bio (if present)
            if (widget.user.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.user.bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Statistics Row: Friends | Followers | Following
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
                borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                border: Border.all(
                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Friends', widget.user.friendsCount, isDark),
                  Container(height: 22, width: 1, color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                  _buildStatItem('Followers', _followersCount, isDark),
                  Container(height: 22, width: 1, color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder),
                  _buildStatItem('Following', widget.user.followingCount, isDark),
                ],
              ),
            ),
            const SizedBox(height: 22),

            if (_isBlocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: HeyTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                  border: Border.all(color: HeyTheme.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: HeyTheme.errorRed, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You blocked @${widget.user.username}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HeyTheme.errorRed,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _handleToggleBlockUser,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Unblock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HeyTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Bottom Equal-Width Action Buttons: [ Message ] [ Follow ]
            if (!_isBlocked)
              Row(
                children: [
                  // [ Message ] Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onSendMessage != null) {
                          widget.onSendMessage!();
                        } else {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final current = auth.currentUser;
                          if (current != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  targetUser: widget.user,
                                  currentUserId: current.uid,
                                  currentUserName: current.displayName,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HeyTheme.primary,
                        side: const BorderSide(color: HeyTheme.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // [ Follow / Following ] Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleFollowToggle,
                      icon: Icon(
                        _isFollowing ? Icons.check_rounded : Icons.person_add_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? (isDark ? HeyTheme.darkBorder : Colors.grey.shade300)
                            : HeyTheme.primary,
                        foregroundColor: _isFollowing
                            ? (isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: _isFollowing ? 0 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, bool isDark) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 17,
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
    );
  }
}
