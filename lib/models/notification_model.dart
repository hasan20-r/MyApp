import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String? senderId;
  final String? senderName;
  final String? senderUsername;
  final String? senderPhotoUrl;
  final String type; // 'new_follower', 'mutual_friend', 'chat_message', 'group_invitation', 'group_role_change', 'group_member_removed'
  final String title;
  final String message;
  final String? targetId;
  final String? chatId;
  final String? groupId;
  final String? groupName;
  final String? groupPhotoUrl;
  final String? role;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    this.senderId,
    this.senderName,
    this.senderUsername,
    this.senderPhotoUrl,
    required this.type,
    required this.title,
    required this.message,
    this.targetId,
    this.chatId,
    this.groupId,
    this.groupName,
    this.groupPhotoUrl,
    this.role,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: id,
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderUsername: map['senderUsername'],
      senderPhotoUrl: map['senderPhotoUrl'],
      type: map['type'] ?? 'general',
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      targetId: map['targetId'],
      chatId: map['chatId'],
      groupId: map['groupId'],
      groupName: map['groupName'],
      groupPhotoUrl: map['groupPhotoUrl'],
      role: map['role'],
      isRead: map['isRead'] ?? false,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderUsername': senderUsername,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type,
      'title': title,
      'message': message,
      'targetId': targetId,
      'chatId': chatId,
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'role': role,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? senderName,
    String? senderUsername,
    String? senderPhotoUrl,
    String? type,
    String? title,
    String? message,
    String? targetId,
    String? chatId,
    String? groupId,
    String? groupName,
    String? groupPhotoUrl,
    String? role,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderUsername: senderUsername ?? this.senderUsername,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      targetId: targetId ?? this.targetId,
      chatId: chatId ?? this.chatId,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      role: role ?? this.role,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
