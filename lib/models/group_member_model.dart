import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberModel {
  final String uid;
  final String groupId;
  final String displayName;
  final String? username;
  final String? photoUrl;
  final String role; // 'admin', 'moderator', 'member'
  final String? nickname; // Group-specific nickname
  final String status; // 'active', 'inactive', 'removed'
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime updatedAt;

  const GroupMemberModel({
    required this.uid,
    required this.groupId,
    required this.displayName,
    this.username,
    this.photoUrl,
    this.role = 'member',
    this.nickname,
    this.status = 'active',
    required this.joinedAt,
    this.leftAt,
    required this.updatedAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isModerator => role.toLowerCase() == 'moderator';
  bool get isRegularMember => role.toLowerCase() == 'member';
  bool get isActive => status.toLowerCase() == 'active';

  String get effectiveName => (nickname != null && nickname!.trim().isNotEmpty)
      ? nickname!.trim()
      : displayName;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'groupId': groupId,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'role': role,
      'nickname': nickname,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GroupMemberModel.fromMap(Map<String, dynamic> map, String documentId) {
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

    return GroupMemberModel(
      uid: (map['uid'] as String?) ?? documentId,
      groupId: (map['groupId'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? 'Hey Fan',
      username: map['username'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: (map['role'] as String?) ?? 'member',
      nickname: map['nickname'] as String?,
      status: (map['status'] as String?) ?? 'active',
      joinedAt: parseDate(map['joinedAt']),
      leftAt: parseNullableDate(map['leftAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
