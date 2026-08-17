import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String uid;
  final String friendUid;
  final DateTime createdAt;

  const FriendModel({
    required this.uid,
    required this.friendUid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'friendUid': friendUid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FriendModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return FriendModel(
      uid: documentId,
      friendUid: (map['friendUid'] as String?) ?? documentId,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
