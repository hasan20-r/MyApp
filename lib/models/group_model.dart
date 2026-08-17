import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> activeMemberIds;
  final int memberCount;
  final String status; // 'active', 'closed'
  final String? lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final DateTime? lastMessageTimestamp;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.activeMemberIds,
    required this.memberCount,
    this.status = 'active',
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageTimestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'activeMemberIds': activeMemberIds,
      'memberCount': memberCount,
      'status': status,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageTimestamp': lastMessageTimestamp != null
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String documentId) {
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

    final rawMembers = map['activeMemberIds'];
    List<String> parsedMembers = [];
    if (rawMembers is List) {
      parsedMembers = rawMembers.map((e) => e.toString()).toList();
    }

    return GroupModel(
      id: documentId,
      name: (map['name'] as String?) ?? 'Group Circle',
      description: map['description'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdBy: (map['createdBy'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      activeMemberIds: parsedMembers,
      memberCount: (map['memberCount'] as num?)?.toInt() ?? parsedMembers.length,
      status: (map['status'] as String?) ?? 'active',
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageSenderName: map['lastMessageSenderName'] as String?,
      lastMessageTimestamp: parseNullableDate(map['lastMessageTimestamp']),
    );
  }
}
