import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/constants.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../models/group_invitation_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get1to1ChatId(String uidA, String uidB) {
    final list = [uidA, uidB]..sort();
    return '${list[0]}_${list[1]}';
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isGreaterThanOrEqualTo: clean)
        .where('username', isLessThanOrEqualTo: '$clean\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  Future<void> setUserPresence(String uid, bool isOnline) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Suppress network presence write errors
    }
  }

  Stream<bool> streamIsFollowing({required String currentUserId, required String targetUserId}) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.followingCollection)
        .doc(targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<bool> isFollowing({required String currentUserId, required String targetUserId}) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.followingCollection)
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  Stream<List<String>> streamFollowingUids(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.followingCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<String>> streamFollowersUids(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.followersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<String>> streamFriendsUids(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.friendsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<void> toggleFollow({
    required String currentUserId,
    required String targetUserId,
    required bool isCurrentlyFollowing,
  }) async {
    // Prevent self-following
    if (currentUserId == targetUserId) return;

    final batch = _firestore.batch();
    final currentRef = _firestore.collection(AppConstants.usersCollection).doc(currentUserId);
    final targetRef = _firestore.collection(AppConstants.usersCollection).doc(targetUserId);

    final followingDoc = currentRef.collection(AppConstants.followingCollection).doc(targetUserId);
    final followerDoc = targetRef.collection(AppConstants.followersCollection).doc(currentUserId);

    final currentFriendDoc = currentRef.collection(AppConstants.friendsCollection).doc(targetUserId);
    final targetFriendDoc = targetRef.collection(AppConstants.friendsCollection).doc(currentUserId);

    // Check if target is already following current user (mutual friendship condition)
    final targetFollowsCurrentDoc = await targetRef
        .collection(AppConstants.followingCollection)
        .doc(currentUserId)
        .get();
    final isTargetFollowingCurrent = targetFollowsCurrentDoc.exists;

    if (isCurrentlyFollowing) {
      batch.delete(followingDoc);
      batch.delete(followerDoc);
      batch.update(currentRef, {'followingCount': FieldValue.increment(-1)});
      batch.update(targetRef, {'followersCount': FieldValue.increment(-1)});

      // If mutual friendship existed, remove friend status from both
      if (isTargetFollowingCurrent) {
        batch.delete(currentFriendDoc);
        batch.delete(targetFriendDoc);
        batch.update(currentRef, {'friendsCount': FieldValue.increment(-1)});
        batch.update(targetRef, {'friendsCount': FieldValue.increment(-1)});
      }
    } else {
      final now = FieldValue.serverTimestamp();
      batch.set(followingDoc, {'createdAt': now});
      batch.set(followerDoc, {'createdAt': now});
      batch.update(currentRef, {'followingCount': FieldValue.increment(1)});
      batch.update(targetRef, {'followersCount': FieldValue.increment(1)});

      final currentUserDoc = await currentRef.get();
      final currentUserData = currentUserDoc.data() ?? {};
      final currentUserName = currentUserData['displayName'] ?? 'A fan';
      final currentUserUsername = currentUserData['username'] ?? '';
      final currentUserPhotoUrl = currentUserData['photoUrl'];

      // If target user already followed current user, automatically become mutual friends!
      if (isTargetFollowingCurrent) {
        batch.set(currentFriendDoc, {'createdAt': now, 'friendUid': targetUserId});
        batch.set(targetFriendDoc, {'createdAt': now, 'friendUid': currentUserId});
        batch.update(currentRef, {'friendsCount': FieldValue.increment(1)});
        batch.update(targetRef, {'friendsCount': FieldValue.increment(1)});

        final targetUserDoc = await targetRef.get();
        final targetUserData = targetUserDoc.data() ?? {};
        final targetUserName = targetUserData['displayName'] ?? 'A fan';
        final targetUserUsername = targetUserData['username'] ?? '';
        final targetUserPhotoUrl = targetUserData['photoUrl'];

        // Activity for Target User: Mutual friend
        final targetNotifRef = targetRef
            .collection(AppConstants.notificationsCollection)
            .doc('mutual_$currentUserId');
        batch.set(targetNotifRef, {
          'recipientId': targetUserId,
          'senderId': currentUserId,
          'senderName': currentUserName,
          'senderUsername': currentUserUsername,
          'senderPhotoUrl': currentUserPhotoUrl,
          'type': 'mutual_friend',
          'title': 'Mutual Friends! 🎉',
          'message': '@$currentUserUsername and you are now mutual friends!',
          'targetId': currentUserId,
          'isRead': false,
          'createdAt': now,
        });

        // Activity for Current User: Mutual friend
        final currentNotifRef = currentRef
            .collection(AppConstants.notificationsCollection)
            .doc('mutual_$targetUserId');
        batch.set(currentNotifRef, {
          'recipientId': currentUserId,
          'senderId': targetUserId,
          'senderName': targetUserName,
          'senderUsername': targetUserUsername,
          'senderPhotoUrl': targetUserPhotoUrl,
          'type': 'mutual_friend',
          'title': 'Mutual Friends! 🎉',
          'message': '@$targetUserUsername and you are now mutual friends!',
          'targetId': targetUserId,
          'isRead': false,
          'createdAt': now,
        });
      } else {
        // Activity for Target User: New follower
        final targetNotifRef = targetRef
            .collection(AppConstants.notificationsCollection)
            .doc('follow_$currentUserId');
        batch.set(targetNotifRef, {
          'recipientId': targetUserId,
          'senderId': currentUserId,
          'senderName': currentUserName,
          'senderUsername': currentUserUsername,
          'senderPhotoUrl': currentUserPhotoUrl,
          'type': 'new_follower',
          'title': 'New Follower',
          'message': '$currentUserName (@$currentUserUsername) started following you.',
          'targetId': currentUserId,
          'isRead': false,
          'createdAt': now,
        });
      }
    }

    await batch.commit();
  }

  Future<void> reportUser({
    required String reportedByUid,
    required String targetUid,
    required String reason,
    String? details,
  }) async {
    await _firestore.collection(AppConstants.reportsCollection).add({
      'reportedBy': reportedByUid,
      'targetUser': targetUid,
      'reason': reason,
      if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    final batch = _firestore.batch();

    // 1. Add to user's blocks subcollection
    final blockRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.blocksCollection)
        .doc(blockedUserId);
    batch.set(blockRef, {'blockedAt': FieldValue.serverTimestamp()});

    // 2. Also remove following / follower relationship if any
    final followingRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.followingCollection)
        .doc(blockedUserId);
    batch.delete(followingRef);

    final followerRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(blockedUserId)
        .collection(AppConstants.followersCollection)
        .doc(currentUserId);
    batch.delete(followerRef);

    await batch.commit();
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.blocksCollection)
        .doc(blockedUserId)
        .delete();
  }

  Future<bool> isUserBlocked({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.blocksCollection)
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  Stream<bool> streamIsUserBlocked({
    required String currentUserId,
    required String targetUserId,
  }) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.blocksCollection)
        .doc(targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<List<String>> streamBlockedUserIds(String currentUserId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.blocksCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
  }

  Future<List<UserModel>> getBlockedUsers(String currentUserId) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.blocksCollection)
        .get();

    final userIds = snapshot.docs.map((d) => d.id).toList();
    if (userIds.isEmpty) return [];

    final List<UserModel> users = [];
    for (final uid in userIds) {
      final user = await getUser(uid);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }

  // --- 1-to-1 Messaging Methods ---

  Future<String> createOrGet1to1Chat({
    required String currentUserId,
    required String targetUserId,
    String? currentUserName,
    String? targetUserName,
  }) async {
    final chatId = get1to1ChatId(currentUserId, targetUserId);
    final chatDocRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
    final doc = await chatDocRef.get();

    if (!doc.exists) {
      final now = FieldValue.serverTimestamp();
      await chatDocRef.set({
        'participants': [currentUserId, targetUserId],
        'createdAt': now,
        'updatedAt': now,
      });
    }

    return chatId;
  }

  Stream<List<ChatModel>> streamUserChats(String currentUserId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && mediaUrl == null) return;

    final batch = _firestore.batch();
    final messageDocRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc();

    final chatDocRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);

    final now = FieldValue.serverTimestamp();
    final previewText = type == 'image' ? '📷 Photo' : cleanText;

    batch.set(messageDocRef, {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': cleanText,
      'type': type,
      'mediaUrl': mediaUrl,
      'createdAt': now,
      'isRead': false,
    });

    batch.update(chatDocRef, {
      'lastMessage': previewText,
      'lastMessageSenderId': senderId,
      'lastMessageSenderName': senderName,
      'lastMessageTimestamp': now,
      'updatedAt': now,
    });

    final chatDoc = await chatDocRef.get();
    if (chatDoc.exists) {
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
      final recipientId = participants.firstWhere((p) => p != senderId, orElse: () => '');
      if (recipientId.isNotEmpty) {
        final notifRef = _firestore
            .collection(AppConstants.usersCollection)
            .doc(recipientId)
            .collection(AppConstants.notificationsCollection)
            .doc('chat_$chatId');

        batch.set(notifRef, {
          'recipientId': recipientId,
          'senderId': senderId,
          'senderName': senderName,
          'type': 'chat_message',
          'title': senderName,
          'message': previewText,
          'chatId': chatId,
          'targetId': senderId,
          'isRead': false,
          'createdAt': now,
        });
      }
    }

    await batch.commit();
  }

  // --- Group Chat System Methods ---

  Future<String> createGroup({
    required String creatorUid,
    required String creatorName,
    String? creatorUsername,
    String? creatorPhotoUrl,
    required String name,
    String? description,
    String? photoUrl,
    List<UserModel>? initialInvitees,
  }) async {
    final groupDocRef = _firestore.collection(AppConstants.groupsCollection).doc();
    final groupId = groupDocRef.id;
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();

    // 1. Create Group Document
    batch.set(groupDocRef, {
      'name': name.trim(),
      'description': description?.trim(),
      'photoUrl': photoUrl,
      'createdBy': creatorUid,
      'createdAt': now,
      'updatedAt': now,
      'activeMemberIds': [creatorUid],
      'memberCount': 1,
      'status': 'active',
      'lastMessage': 'Group Circle created 🎉',
      'lastMessageSenderId': creatorUid,
      'lastMessageSenderName': creatorName,
      'lastMessageTimestamp': now,
    });

    // 2. Add Creator as Admin Member
    final creatorMemberRef = groupDocRef
        .collection(AppConstants.groupMembersCollection)
        .doc(creatorUid);

    batch.set(creatorMemberRef, {
      'uid': creatorUid,
      'groupId': groupId,
      'displayName': creatorName,
      'username': creatorUsername,
      'photoUrl': creatorPhotoUrl,
      'role': 'admin',
      'nickname': null,
      'status': 'active',
      'joinedAt': now,
      'updatedAt': now,
    });

    // 3. If initial invitees provided, create pending invitations
    if (initialInvitees != null && initialInvitees.isNotEmpty) {
      for (final invitee in initialInvitees) {
        if (invitee.uid == creatorUid) continue;
        final inviteRef = _firestore.collection(AppConstants.groupInvitationsCollection).doc();
        batch.set(inviteRef, {
          'groupId': groupId,
          'groupName': name.trim(),
          'groupPhotoUrl': photoUrl,
          'inviterUid': creatorUid,
          'inviterName': creatorName,
          'invitedUid': invitee.uid,
          'status': 'pending',
          'createdAt': now,
        });

        final notifRef = _firestore
            .collection(AppConstants.usersCollection)
            .doc(invitee.uid)
            .collection(AppConstants.notificationsCollection)
            .doc('invite_$groupId');
        batch.set(notifRef, {
          'recipientId': invitee.uid,
          'senderId': creatorUid,
          'senderName': creatorName,
          'type': 'group_invitation',
          'title': 'Group Invitation',
          'message': '$creatorName invited you to join "${name.trim()}"',
          'groupId': groupId,
          'groupName': name.trim(),
          'groupPhotoUrl': photoUrl,
          'isRead': false,
          'createdAt': now,
        });
      }
    }

    await batch.commit();
    return groupId;
  }

  Stream<List<GroupModel>> streamUserGroups(String uid) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .where('activeMemberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
          .where((g) => g.status == 'active')
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Stream<GroupModel?> streamGroup(String groupId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return GroupModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  Future<GroupModel?> getGroup(String groupId) async {
    final doc = await _firestore.collection(AppConstants.groupsCollection).doc(groupId).get();
    if (!doc.exists || doc.data() == null) return null;
    return GroupModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<GroupMemberModel>> streamGroupMembers(String groupId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMembersCollection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupMemberModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<GroupMemberModel?> streamGroupMember({
    required String groupId,
    required String uid,
  }) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMembersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return GroupMemberModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  Stream<List<MessageModel>> streamGroupMessages(String groupId) {
    return _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMessagesCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && mediaUrl == null) return;

    final groupRef = _firestore.collection(AppConstants.groupsCollection).doc(groupId);
    final groupDoc = await groupRef.get();
    if (!groupDoc.exists) throw Exception('Group does not exist');
    final groupData = groupDoc.data()!;
    final activeMembers = List<String>.from(groupData['activeMemberIds'] ?? []);

    if (!activeMembers.contains(senderId)) {
      throw Exception('Only active members can send messages to this group.');
    }

    final batch = _firestore.batch();
    final messageDocRef = groupRef
        .collection(AppConstants.groupMessagesCollection)
        .doc();

    final now = FieldValue.serverTimestamp();
    final previewText = type == 'image' ? '📷 Photo' : cleanText;

    batch.set(messageDocRef, {
      'chatId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'text': cleanText,
      'type': type,
      'mediaUrl': mediaUrl,
      'createdAt': now,
      'isRead': true,
    });

    batch.update(groupRef, {
      'lastMessage': previewText,
      'lastMessageSenderId': senderId,
      'lastMessageSenderName': senderName,
      'lastMessageTimestamp': now,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> updateMemberNickname({
    required String groupId,
    required String uid,
    required String nickname,
  }) async {
    final memberRef = _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMembersCollection)
        .doc(uid);

    final cleanNickname = nickname.trim();
    await memberRef.update({
      'nickname': cleanNickname.isEmpty ? null : cleanNickname,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String targetUid,
    required String newRole, // 'admin', 'moderator', 'member'
    required String currentAdminUid,
  }) async {
    final adminMemberDoc = await _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMembersCollection)
        .doc(currentAdminUid)
        .get();

    if (!adminMemberDoc.exists || adminMemberDoc.data()?['role'] != 'admin') {
      throw Exception('Only Admins can change member roles.');
    }

    final group = await getGroup(groupId);
    final groupName = group?.name ?? 'Group';
    final roleName = newRole[0].toUpperCase() + newRole.substring(1);

    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMembersCollection)
        .doc(targetUid);

    final now = FieldValue.serverTimestamp();
    batch.update(memberRef, {
      'role': newRole,
      'updatedAt': now,
    });

    final notifRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUid)
        .collection(AppConstants.notificationsCollection)
        .doc('role_${groupId}_$targetUid');

    batch.set(notifRef, {
      'recipientId': targetUid,
      'senderId': currentAdminUid,
      'type': 'group_role_change',
      'title': 'Role Updated',
      'message': 'Your role was updated to $roleName in "$groupName"',
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoUrl': group?.photoUrl,
      'role': newRole,
      'isRead': false,
      'createdAt': now,
    });

    await batch.commit();
  }

  Future<void> removeMember({
    required String groupId,
    required String targetUid,
    required String removerUid,
  }) async {
    final groupRef = _firestore.collection(AppConstants.groupsCollection).doc(groupId);
    final removerDoc = await groupRef
        .collection(AppConstants.groupMembersCollection)
        .doc(removerUid)
        .get();

    if (!removerDoc.exists) throw Exception('Unauthorized to remove member.');
    final removerRole = removerDoc.data()?['role'] ?? 'member';

    final targetDoc = await groupRef
        .collection(AppConstants.groupMembersCollection)
        .doc(targetUid)
        .get();

    if (!targetDoc.exists) return;
    final targetRole = targetDoc.data()?['role'] ?? 'member';

    if (removerRole == 'moderator') {
      if (targetRole == 'admin' || targetRole == 'moderator') {
        throw Exception('Moderators cannot remove Admins or other Moderators.');
      }
    } else if (removerRole != 'admin') {
      throw Exception('Only Admins and Moderators can remove members.');
    }

    final batch = _firestore.batch();
    final targetMemberRef = groupRef
        .collection(AppConstants.groupMembersCollection)
        .doc(targetUid);

    final now = FieldValue.serverTimestamp();
    batch.update(targetMemberRef, {
      'status': 'removed',
      'leftAt': now,
      'updatedAt': now,
    });

    batch.update(groupRef, {
      'activeMemberIds': FieldValue.arrayRemove([targetUid]),
      'memberCount': FieldValue.increment(-1),
      'updatedAt': now,
    });

    final group = await getGroup(groupId);
    final groupName = group?.name ?? 'Group';
    final notifRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUid)
        .collection(AppConstants.notificationsCollection)
        .doc('removed_${groupId}_$targetUid');

    batch.set(notifRef, {
      'recipientId': targetUid,
      'senderId': removerUid,
      'type': 'group_member_removed',
      'title': 'Group Update',
      'message': 'You were removed from "$groupName"',
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoUrl': group?.photoUrl,
      'isRead': false,
      'createdAt': now,
    });

    await batch.commit();
  }

  Future<void> leaveGroup({
    required String groupId,
    required String uid,
  }) async {
    final groupRef = _firestore.collection(AppConstants.groupsCollection).doc(groupId);
    
    // Check if user is the only active admin
    final membersSnapshot = await groupRef
        .collection(AppConstants.groupMembersCollection)
        .where('status', isEqualTo: 'active')
        .get();

    final activeMembers = membersSnapshot.docs
        .map((d) => GroupMemberModel.fromMap(d.data(), d.id))
        .toList();

    final currentMember = activeMembers.firstWhere(
      (m) => m.uid == uid,
      orElse: () => throw Exception('You are not an active member of this group.'),
    );

    if (currentMember.isAdmin) {
      final activeAdmins = activeMembers.where((m) => m.isAdmin).toList();
      if (activeAdmins.length == 1 && activeMembers.length > 1) {
        throw Exception('Please promote another member to Admin before leaving this group.');
      }
    }

    final batch = _firestore.batch();
    final memberRef = groupRef
        .collection(AppConstants.groupMembersCollection)
        .doc(uid);

    final now = FieldValue.serverTimestamp();
    batch.update(memberRef, {
      'status': 'inactive',
      'leftAt': now,
      'updatedAt': now,
    });

    batch.update(groupRef, {
      'activeMemberIds': FieldValue.arrayRemove([uid]),
      'memberCount': FieldValue.increment(-1),
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> inviteUserToGroup({
    required String groupId,
    required String groupName,
    String? groupPhotoUrl,
    required String inviterUid,
    required String inviterName,
    required String invitedUid,
  }) async {
    // Check if user is already an active member
    final groupDoc = await _firestore.collection(AppConstants.groupsCollection).doc(groupId).get();
    if (!groupDoc.exists) throw Exception('Group does not exist');
    final activeMembers = List<String>.from(groupDoc.data()?['activeMemberIds'] ?? []);
    if (activeMembers.contains(invitedUid)) {
      throw Exception('User is already an active member of this group.');
    }

    // Check if pending invitation already exists
    final existingInvites = await _firestore
        .collection(AppConstants.groupInvitationsCollection)
        .where('groupId', isEqualTo: groupId)
        .where('invitedUid', isEqualTo: invitedUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvites.docs.isNotEmpty) {
      throw Exception('An invitation has already been sent to this user.');
    }

    final batch = _firestore.batch();
    final inviteRef = _firestore.collection(AppConstants.groupInvitationsCollection).doc();
    final now = FieldValue.serverTimestamp();

    batch.set(inviteRef, {
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'inviterUid': inviterUid,
      'inviterName': inviterName,
      'invitedUid': invitedUid,
      'status': 'pending',
      'createdAt': now,
    });

    final notifRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(invitedUid)
        .collection(AppConstants.notificationsCollection)
        .doc('invite_$groupId');

    batch.set(notifRef, {
      'recipientId': invitedUid,
      'senderId': inviterUid,
      'senderName': inviterName,
      'type': 'group_invitation',
      'title': 'Group Invitation',
      'message': '$inviterName invited you to join "$groupName"',
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'isRead': false,
      'createdAt': now,
    });

    await batch.commit();
  }

  Stream<List<GroupInvitationModel>> streamUserGroupInvitations(String uid) {
    return _firestore
        .collection(AppConstants.groupInvitationsCollection)
        .where('invitedUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupInvitationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> acceptGroupInvitation({
    required String invitationId,
    required String groupId,
    required UserModel user,
  }) async {
    final batch = _firestore.batch();
    final inviteRef = _firestore.collection(AppConstants.groupInvitationsCollection).doc(invitationId);
    final groupRef = _firestore.collection(AppConstants.groupsCollection).doc(groupId);
    final memberRef = groupRef
        .collection(AppConstants.groupMembersCollection)
        .doc(user.uid);

    final now = FieldValue.serverTimestamp();

    batch.update(inviteRef, {'status': 'accepted', 'updatedAt': now});

    batch.set(memberRef, {
      'uid': user.uid,
      'groupId': groupId,
      'displayName': user.displayName,
      'username': user.username,
      'photoUrl': user.photoUrl,
      'role': 'member',
      'nickname': null,
      'status': 'active',
      'joinedAt': now,
      'leftAt': null,
      'updatedAt': now,
    }, SetOptions(merge: true));

    batch.update(groupRef, {
      'activeMemberIds': FieldValue.arrayUnion([user.uid]),
      'memberCount': FieldValue.increment(1),
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> declineGroupInvitation(String invitationId) async {
    await _firestore
        .collection(AppConstants.groupInvitationsCollection)
        .doc(invitationId)
        .update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGroupDetails({
    required String groupId,
    required String adminUid,
    String? name,
    String? description,
    String? photoUrl,
  }) async {
    final memberDoc = await _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMembersCollection)
        .doc(adminUid)
        .get();

    if (!memberDoc.exists || memberDoc.data()?['role'] != 'admin') {
      throw Exception('Only Admins can modify group details.');
    }

    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null && name.trim().isNotEmpty) updates['name'] = name.trim();
    if (description != null) updates['description'] = description.trim();
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestore.collection(AppConstants.groupsCollection).doc(groupId).update(updates);
  }

  Future<void> closeGroup({
    required String groupId,
    required String adminUid,
  }) async {
    final memberDoc = await _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.groupMembersCollection)
        .doc(adminUid)
        .get();

    if (!memberDoc.exists || memberDoc.data()?['role'] != 'admin') {
      throw Exception('Only Admins can close this group.');
    }

    await _firestore.collection(AppConstants.groupsCollection).doc(groupId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Notifications & Activity Methods ---

  Stream<List<NotificationModel>> streamNotifications(String uid, {int limit = 50}) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.notificationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<int> streamUnreadNotificationsCount(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.notificationsCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  Future<void> markAllNotificationsAsRead(String uid) async {
    final unreadDocs = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.notificationsCollection)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadDocs.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String uid, String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (_) {}
  }

  Future<void> clearAllNotifications(String uid) async {
    final docs = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.notificationsCollection)
        .get();

    if (docs.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

