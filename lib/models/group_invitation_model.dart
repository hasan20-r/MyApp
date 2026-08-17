import 'package:cloud_firestore/cloud_firestore.dart';

class GroupInvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final String inviterUid;
  final String inviterName;
  final String invitedUid;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  const GroupInvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.groupPhotoUrl,
    required this.inviterUid,
    required this.inviterName,
    required this.invitedUid,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'inviterUid': inviterUid,
      'inviterName': inviterName,
      'invitedUid': invitedUid,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GroupInvitationModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return GroupInvitationModel(
      id: documentId,
      groupId: (map['groupId'] as String?) ?? '',
      groupName: (map['groupName'] as String?) ?? 'Group Circle',
      groupPhotoUrl: map['groupPhotoUrl'] as String?,
      inviterUid: (map['inviterUid'] as String?) ?? '',
      inviterName: (map['inviterName'] as String?) ?? 'Hey Fan',
      invitedUid: (map['invitedUid'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
