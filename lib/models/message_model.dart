import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final String type; // 'text', 'image'
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = 'text',
    this.mediaUrl,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MessageModel(
      id: documentId,
      chatId: (map['chatId'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      senderName: (map['senderName'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'text',
      mediaUrl: map['mediaUrl'] as String?,
      createdAt: parseDate(map['createdAt']),
      isRead: (map['isRead'] as bool?) ?? false,
    );
  }
}
