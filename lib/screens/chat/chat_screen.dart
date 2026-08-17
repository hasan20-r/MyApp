import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/hey_avatar.dart';
import '../../widgets/hey_image_viewer.dart';
import '../../widgets/safety_dialogs.dart';
import '../profile/user_profile_modal.dart';

class ChatScreen extends StatefulWidget {
  final UserModel targetUser;
  final String currentUserId;
  final String currentUserName;

  const ChatScreen({
    super.key,
    required this.targetUser,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  String? _chatId;
  bool _isSending = false;
  bool _isUploadingMedia = false;
  bool _isBlocked = false;

  // Local message fallback list for preview or offline use
  final List<MessageModel> _fallbackMessages = [];

  @override
  void initState() {
    super.initState();
    _chatId = _firestoreService.get1to1ChatId(widget.currentUserId, widget.targetUser.uid);
    NotificationService().setActiveConversation(chatId: _chatId);
    _checkBlockStatus();
    _initChat();
  }

  Future<void> _checkBlockStatus() async {
    final blocked = await _firestoreService.isUserBlocked(
      currentUserId: widget.currentUserId,
      targetUserId: widget.targetUser.uid,
    );
    if (mounted) {
      setState(() {
        _isBlocked = blocked;
      });
    }
  }

  void _handleViewProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileModal(
        user: widget.targetUser,
        isFollowing: false,
        onBlockUser: () {
          if (mounted) {
            setState(() => _isBlocked = true);
          }
        },
      ),
    );
  }

  void _handleReportUser() {
    HeySafetyDialogs.showReportDialog(
      context,
      targetUser: widget.targetUser,
      currentUserId: widget.currentUserId,
    );
  }

  void _handleToggleBlockUser() {
    if (_isBlocked) {
      HeySafetyDialogs.showUnblockConfirmationDialog(
        context,
        targetUser: widget.targetUser,
        currentUserId: widget.currentUserId,
        onUnblocked: () {
          if (mounted) {
            setState(() => _isBlocked = false);
          }
        },
      );
    } else {
      HeySafetyDialogs.showBlockConfirmationDialog(
        context,
        targetUser: widget.targetUser,
        currentUserId: widget.currentUserId,
        onBlocked: () {
          if (mounted) {
            setState(() => _isBlocked = true);
          }
        },
      );
    }
  }

  void _initChat() async {
    try {
      final id = await _firestoreService.createOrGet1to1Chat(
        currentUserId: widget.currentUserId,
        targetUserId: widget.targetUser.uid,
        currentUserName: widget.currentUserName,
        targetUserName: widget.targetUser.displayName,
      );
      NotificationService().setActiveConversation(chatId: id);
      if (mounted) {
        setState(() {
          _chatId = id;
        });
      }
    } catch (_) {
      // Offline or preview fallback
      if (_fallbackMessages.isEmpty) {
        setState(() {
          _fallbackMessages.add(
            MessageModel(
              id: 'm1',
              chatId: _chatId ?? 'chat_demo',
              senderId: widget.targetUser.uid,
              senderName: widget.targetUser.displayName,
              text: 'Hey there! Great to connect with you on Hey Fans 🎉',
              createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
              isRead: true,
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    NotificationService().clearActiveConversation();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final activeChatId = _chatId ?? _firestoreService.get1to1ChatId(widget.currentUserId, widget.targetUser.uid);

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      await _firestoreService.sendMessage(
        chatId: activeChatId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: text,
      );
    } catch (e) {
      // Local fallback in preview
      setState(() {
        _fallbackMessages.add(
          MessageModel(
            id: 'm_${DateTime.now().millisecondsSinceEpoch}',
            chatId: activeChatId,
            senderId: widget.currentUserId,
            senderName: widget.currentUserName,
            text: text,
            createdAt: DateTime.now(),
            isRead: false,
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

  void _showMediaPickerSheet() {
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
                subtitle: const Text('Share photos from your device album'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.gallery);
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
                subtitle: const Text('Use camera to capture and send immediately'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
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

      final activeChatId = _chatId ?? _firestoreService.get1to1ChatId(widget.currentUserId, widget.targetUser.uid);
      final messageId = 'img_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Upload to Firebase Storage
      final downloadUrl = await _storageService.uploadChatMedia(
        chatId: activeChatId,
        messageId: messageId,
        file: file,
      );

      // 2. Post Firestore message
      await _firestoreService.sendMessage(
        chatId: activeChatId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: '',
        type: 'image',
        mediaUrl: downloadUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString().replaceAll('Exception: ', '')}'),
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

  Widget _buildMessageContent(MessageModel msg, bool isMe, bool isDark) {
    final isImage = msg.type == 'image' || (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (isImage && msg.mediaUrl != null) ...[
          GestureDetector(
            onTap: () {
              HeyImageViewer.show(
                context,
                imageUrl: msg.mediaUrl!,
                title: 'Shared by ${msg.senderName}',
                heroTag: 'msg_${msg.id}',
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
                  tag: 'msg_${msg.id}',
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
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                size: 13,
                color: Colors.white.withAlpha(210),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            HeyAvatar(
              photoUrl: widget.targetUser.photoUrl,
              name: widget.targetUser.displayName,
              radius: 18,
              isOnline: widget.targetUser.isOnline,
              showPresence: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.targetUser.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.targetUser.isOnline ? 'Online' : '@${widget.targetUser.username}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.targetUser.isOnline
                          ? const Color(0xFF10B981)
                          : (isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Chat options',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
            ),
            color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
            elevation: 8,
            onSelected: (value) {
              if (value == 'profile') _handleViewProfile();
              if (value == 'report') _handleReportUser();
              if (value == 'block') _handleToggleBlockUser();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18, color: HeyTheme.primary),
                    SizedBox(width: 12),
                    Text('View Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text('Report @${widget.targetUser.username}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
                      _isBlocked ? 'Unblock @${widget.targetUser.username}' : 'Block @${widget.targetUser.username}',
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
      body: SafeArea(
        child: Column(
          children: [
            // Uploading progress banner
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
                      'Uploading photo...',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HeyTheme.primary),
                    ),
                  ],
                ),
              ),

            // Messages List Area
            Expanded(
              child: _chatId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<MessageModel>>(
                      stream: _firestoreService.streamMessages(_chatId!),
                      builder: (context, snapshot) {
                        final messages = (snapshot.hasData && snapshot.data!.isNotEmpty)
                            ? snapshot.data!
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
                                      Icons.chat_bubble_outline_rounded,
                                      size: 32,
                                      color: HeyTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Say hello to ${widget.targetUser.displayName} 👋',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Direct messages and photos are end-to-end synchronized.',
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
                            final isMe = msg.senderId == widget.currentUserId;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                                child: _buildMessageContent(msg, isMe, isDark),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Message Input Bar or Blocked Notice
            if (_isBlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    const Icon(Icons.block_rounded, color: HeyTheme.errorRed, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You blocked @${widget.targetUser.username}. You cannot message each other.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleToggleBlockUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HeyTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                        ),
                      ),
                      child: const Text(
                        'Unblock',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                      tooltip: 'Send photo',
                      onPressed: _isUploadingMedia ? null : _showMediaPickerSheet,
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
                            hintText: 'Write a message...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
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
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
