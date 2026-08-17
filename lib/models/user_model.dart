import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final bool isOnline;
  final DateTime lastSeen;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
    this.isOnline = false,
    required this.lastSeen,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'friendsCount': friendsCount,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      uid: documentId,
      email: (map['email'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: (map['bio'] as String?) ?? '',
      followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
      friendsCount: (map['friendsCount'] as num?)?.toInt() ?? 0,
      isOnline: (map['isOnline'] as bool?) ?? false,
      lastSeen: parseDate(map['lastSeen']),
      fcmToken: map['fcmToken'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? photoUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? friendsCount,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      friendsCount: friendsCount ?? this.friendsCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
