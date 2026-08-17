import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/constants.dart';
import '../app/routes.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/group/group_chat_screen.dart';
import '../screens/group/group_invitations_modal.dart';
import '../screens/profile/user_profile_modal.dart';
import 'firestore_service.dart';

/// Top-level background message handler required by FirebaseMessaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM background message receiver
  if (kDebugMode) {
    print('FCM Background message received: ${message.messageId}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();

  static const String channelId = 'hey_fans_channel';
  static const String channelName = 'Hey Fans Notifications';
  static const String channelDescription = 'Notifications for messages, groups, followers, and invitations';

  bool _isInitialized = false;
  String? _activeChatId;
  String? _activeGroupId;
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setActiveConversation({String? chatId, String? groupId}) {
    _activeChatId = chatId;
    _activeGroupId = groupId;
  }

  void clearActiveConversation() {
    _activeChatId = null;
    _activeGroupId = null;
  }

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) return;
    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    }

    try {
      // 1. Request notification permissions (POST_NOTIFICATIONS on Android 13+)
      await requestPermission();

      // 2. Setup Flutter Local Notifications with high-priority channel
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _handlePayloadRouting(payload);
          }
        },
      );

      // Create Android Notification Channel
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Foreground presentation options for iOS/macOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Background message callback handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 6. Handle notification click when app is in background and brought to foreground
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageRouting(message.data);
      });

      // 7. Check if app was launched from terminated state via a notification click
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessageRouting(initialMessage.data);
        });
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService initialize exception: $e');
      }
    }
  }

  Future<void> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      if (kDebugMode) {
        print('Notification authorization status: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permission: $e');
      }
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM device token: $e');
      }
      return null;
    }
  }

  void listenToTokenRefresh(String currentUserId) {
    _fcm.onTokenRefresh.listen((newToken) async {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(currentUserId)
            .update({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) {
          print('Failed to update refreshed FCM token in Firestore: $e');
        }
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final chatId = data['chatId'] as String?;
    final groupId = data['groupId'] as String?;

    // Suppress notification if user is actively viewing this specific 1-to-1 or group chat
    if (type == 'chat_message' && chatId != null && _activeChatId == chatId) {
      return;
    }
    if (type == 'group_message' && groupId != null && _activeGroupId == groupId) {
      return;
    }

    final notification = message.notification;
    final title = notification?.title ?? data['title'] ?? 'Hey Fans';
    final body = notification?.body ?? data['body'] ?? 'You have a new update';

    final id = message.messageId.hashCode;

    // Convert data to query-like payload string
    final payloadString = _encodePayload(data);

    showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payloadString,
    );
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, String> _decodePayload(String payload) {
    final map = <String, String>{};
    final pairs = payload.split('&');
    for (final pair in pairs) {
      final kv = pair.split('=');
      if (kv.length == 2) {
        map[kv[0]] = kv[1];
      }
    }
    return map;
  }

  void _handlePayloadRouting(String payload) {
    final data = _decodePayload(payload);
    _handleMessageRouting(data);
  }

  void _handleMessageRouting(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    if (type == null) return;

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final currentUserId = data['recipientUserId'] ?? data['currentUserId'];

    switch (type) {
      case 'chat_message':
        final senderId = data['senderId'] as String?;
        if (senderId != null) {
          final senderUser = await _firestoreService.getUser(senderId);
          if (senderUser != null && context.mounted) {
            final currentUser = await _firestoreService.getUser(currentUserId ?? '');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  targetUser: senderUser,
                  currentUserId: currentUserId ?? '',
                  currentUserName: currentUser?.displayName ?? 'Me',
                ),
              ),
            );
          }
        }
        break;

      case 'group_message':
        final groupId = data['groupId'] as String?;
        if (groupId != null) {
          final group = await _firestoreService.getGroup(groupId);
          final currentUser = await _firestoreService.getUser(currentUserId ?? '');
          if (group != null && currentUser != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  group: group,
                  currentUser: currentUser,
                ),
              ),
            );
          }
        }
        break;

      case 'new_follower':
      case 'mutual_friend':
        final senderId = data['senderId'] as String?;
        if (senderId != null) {
          final followerUser = await _firestoreService.getUser(senderId);
          if (followerUser != null && context.mounted) {
            UserProfileModal.show(
              context,
              user: followerUser,
              isFollowing: type == 'mutual_friend',
            );
          }
        }
        break;

      case 'group_invitation':
        final currentUser = await _firestoreService.getUser(currentUserId ?? '');
        if (currentUser != null && context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => GroupInvitationsModal(currentUser: currentUser),
          );
        }
        break;

      case 'group_role_change':
        final groupId = data['groupId'] as String?;
        if (groupId != null) {
          final group = await _firestoreService.getGroup(groupId);
          final currentUser = await _firestoreService.getUser(currentUserId ?? '');
          if (group != null && currentUser != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  group: group,
                  currentUser: currentUser,
                ),
              ),
            );
          }
        }
        break;

      case 'activity':
      case 'notifications':
        Navigator.of(context).pushNamed(AppRoutes.notifications);
        break;

      default:
        break;
    }
  }
}
