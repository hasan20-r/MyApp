import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final DateTime? lastMessageTimestamp;
  final Map<String, int>? unreadCounts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageTimestamp,
    this.unreadCounts,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageTimestamp': lastMessageTimestamp != null ? Timestamp.fromDate(lastMessageTimestamp!) : null,
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawParticipants = map['participants'];
    List<String> parsedParticipants = [];
    if (rawParticipants is List) {
      parsedParticipants = rawParticipants.map((e) => e.toString()).toList();
    }

    Map<String, int>? parsedUnreads;
    if (map['unreadCounts'] is Map) {
      parsedUnreads = (map['unreadCounts'] as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      );
    }

    return ChatModel(
      id: documentId,
      participants: parsedParticipants,
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageSenderName: map['lastMessageSenderName'] as String?,
      lastMessageTimestamp: parseNullableDate(map['lastMessageTimestamp']),
      unreadCounts: parsedUnreads,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
