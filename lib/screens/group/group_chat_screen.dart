import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/group_member_model.dart';
import '../../models/group_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/hey_image_viewer.dart';
import 'group_info_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;
  final UserModel currentUser;
  final List<UserModel> friends;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.currentUser,
    this.friends = const [],
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  late GroupModel _group;
  bool _isSending = false;
  bool _isUploadingMedia = false;

  // Fallback messages for preview / demo
  final List<MessageModel> _fallbackMessages = [];

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    NotificationService().setActiveConversation(groupId: _group.id);
    _initFallbackMessages();
  }

  void _initFallbackMessages() {
    _fallbackMessages.addAll([
      MessageModel(
        id: 'gm1',
        chatId: _group.id,
        senderId: 'user_fan_1',
        senderName: 'Maya Lin',
        text: 'Welcome everyone to the ${_group.name}! 🎉✨',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      MessageModel(
        id: 'gm2',
        chatId: _group.id,
        senderId: 'user_fan_2',
        senderName: 'David K.',
        text: 'Super excited for upcoming events and fan discussions! 🍿',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        isRead: true,
      ),
    ]);
  }

  @override
  void dispose() {
    NotificationService().clearActiveConversation();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String senderDisplayName) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      await _firestoreService.sendGroupMessage(
        groupId: _group.id,
        senderId: widget.currentUser.uid,
        senderName: senderDisplayName,
        text: text,
      );
    } catch (e) {
      // Local fallback in preview
      setState(() {
        _fallbackMessages.add(
          MessageModel(
            id: 'gm_${DateTime.now().millisecondsSinceEpoch}',
            chatId: _group.id,
            senderId: widget.currentUser.uid,
            senderName: senderDisplayName,
            text: text,
            createdAt: DateTime.now(),
            isRead: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _showMediaPickerSheet(String senderDisplayName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HeyTheme.radiusMedium)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeyTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: HeyTheme.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share photos with this group circle'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendGroupImage(ImageSource.gallery, senderDisplayName);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HeyTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: HeyTheme.secondary),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture live and share to group'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendGroupImage(ImageSource.camera, senderDisplayName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendGroupImage(ImageSource source, String senderDisplayName) async {
    if (_isSending || _isUploadingMedia) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (!await file.exists()) return;

      setState(() {
        _isUploadingMedia = true;
        _isSending = true;
      });

      final messageId = 'gimg_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Upload to Firebase Storage under groups/{groupId}/media/
      final downloadUrl = await _storageService.uploadGroupMedia(
        groupId: _group.id,
        messageId: messageId,
        file: file,
      );

      // 2. Post Group Message in Firestore
      await _firestoreService.sendGroupMessage(
        groupId: _group.id,
        senderId: widget.currentUser.uid,
        senderName: senderDisplayName,
        text: '',
        type: 'image',
        mediaUrl: downloadUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share group photo: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Widget _buildGroupMessageContent({
    required MessageModel msg,
    required bool isMe,
    required bool isDark,
    required String senderDisplayName,
    required String? senderRole,
  }) {
    final isImage = msg.type == 'image' || (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Sender Header for incoming messages
        if (!isMe) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                senderDisplayName,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: HeyTheme.primary,
                ),
              ),
              if (senderRole != null && senderRole != 'member') ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: senderRole == 'admin'
                        ? HeyTheme.primary.withAlpha(30)
                        : HeyTheme.warningOrange.withAlpha(30),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    senderRole.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: senderRole == 'admin' ? HeyTheme.primary : HeyTheme.warningOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
        ],

        // Image Attachment
        if (isImage && msg.mediaUrl != null) ...[
          GestureDetector(
            onTap: () {
              HeyImageViewer.show(
                context,
                imageUrl: msg.mediaUrl!,
                title: 'Photo from $senderDisplayName',
                heroTag: 'gmsg_${msg.id}',
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  maxWidth: 260,
                ),
                color: Colors.black.withOpacity(0.08),
                child: Hero(
                  tag: 'gmsg_${msg.id}',
                  child: Image.network(
                    msg.mediaUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        width: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isMe ? Colors.white : HeyTheme.primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.withOpacity(0.2),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Image failed to load', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (msg.text.isNotEmpty) const SizedBox(height: 6),
        ],

        // Message text
        if (msg.text.isNotEmpty)
          Text(
            msg.text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: isMe
                  ? Colors.white
                  : (isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withAlpha(190)
                    : (isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<GroupModel?>(
      stream: _firestoreService.streamGroup(_group.id),
      builder: (context, groupSnapshot) {
        final currentGroup = groupSnapshot.data ?? _group;

        return StreamBuilder<List<GroupMemberModel>>(
          stream: _firestoreService.streamGroupMembers(currentGroup.id),
          builder: (context, membersSnapshot) {
            final members = membersSnapshot.data ?? [];
            final Map<String, GroupMemberModel> memberMap = {
              for (var m in members) m.uid: m,
            };

            final myMemberDoc = memberMap[widget.currentUser.uid];
            final isActiveMember = currentGroup.activeMemberIds.contains(widget.currentUser.uid);
            final myEffectiveName = myMemberDoc?.effectiveName ?? widget.currentUser.displayName;

            return Scaffold(
              backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
              appBar: AppBar(
                titleSpacing: 0,
                title: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupInfoScreen(
                          group: currentGroup,
                          currentUser: widget.currentUser,
                          friends: widget.friends,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      HeyAvatar(
                        photoUrl: currentGroup.photoUrl,
                        name: currentGroup.name,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentGroup.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${currentGroup.memberCount} members • Tap for info',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    tooltip: 'Group Information',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupInfoScreen(
                            group: currentGroup,
                            currentUser: widget.currentUser,
                            friends: widget.friends,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    // Upload progress banner
                    if (_isUploadingMedia)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: HeyTheme.primary.withOpacity(0.12),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: HeyTheme.primary),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Uploading group photo...',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HeyTheme.primary),
                            ),
                          ],
                        ),
                      ),

                    // Group Messages Feed
                    Expanded(
                      child: StreamBuilder<List<MessageModel>>(
                        stream: _firestoreService.streamGroupMessages(currentGroup.id),
                        builder: (context, msgSnapshot) {
                          final messages = (msgSnapshot.hasData && msgSnapshot.data!.isNotEmpty)
                              ? msgSnapshot.data!
                              : _fallbackMessages;

                          if (messages.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.groups_rounded,
                                        size: 32,
                                        color: HeyTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Welcome to ${currentGroup.name}! 🎉',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Be the first to share a thought or photo with the community.',
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

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg.senderId == widget.currentUser.uid;
                              final senderMember = memberMap[msg.senderId];
                              final senderDisplayName = senderMember?.effectiveName ?? msg.senderName;
                              final senderRole = senderMember?.role;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: isMe
                                        ? const LinearGradient(
                                            colors: [HeyTheme.primary, HeyTheme.primaryDark],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isMe
                                        ? null
                                        : (isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(HeyTheme.radiusMedium),
                                      topRight: const Radius.circular(HeyTheme.radiusMedium),
                                      bottomLeft: Radius.circular(isMe ? HeyTheme.radiusMedium : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : HeyTheme.radiusMedium),
                                    ),
                                    border: isMe
                                        ? null
                                        : Border.all(
                                            color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(isDark ? 30 : 10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _buildGroupMessageContent(
                                    msg: msg,
                                    isMe: isMe,
                                    isDark: isDark,
                                    senderDisplayName: senderDisplayName,
                                    senderRole: senderRole,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Input Bar or Inactive Member Message
                    if (!isActiveMember)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: HeyTheme.errorRed, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are not an active member of this group. Rejoin via invitation to participate.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                          border: Border(
                            top: BorderSide(
                              color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.image_outlined,
                                color: _isUploadingMedia
                                    ? HeyTheme.primary
                                    : (isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary),
                              ),
                              tooltip: 'Send photo to group',
                              onPressed: _isUploadingMedia ? null : () => _showMediaPickerSheet(myEffectiveName),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
                                  borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                                  border: Border.all(
                                    color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                                  ),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Message as $myEffectiveName...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onSubmitted: (_) => _sendMessage(myEffectiveName),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [HeyTheme.primary, HeyTheme.primaryDark],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                onPressed: () => _sendMessage(myEffectiveName),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
