import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // navigatorKey için
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'NotifyReader/notify_reader_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (_shouldUseLocalNotifications()) {
    await NotificationService.instance.setupFlutterNotifications();
    await NotificationService.instance.showNotification(message);
  }
}

bool _shouldUseLocalNotifications() {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;
  static bool _bgRegistered = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authStateSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  bool _isHandlingTap = false;
  static const String _fcmTokenKeyPrefix = 'fcm_token';

  Future<void> initialize() async {
    if (!_bgRegistered) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      _bgRegistered = true;
    }
    await _requestPermission();
    await _configureForegroundPresentation();
    await setupFlutterNotifications();
    _bindTokenSyncListeners();
    await _syncCurrentToken();
    _setupMessageHandlers();
  }

  void _bindTokenSyncListeners() {
    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
    });

    _authStateSub ??=
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _syncCurrentToken();
      }
    });
  }

  Future<void> _syncCurrentToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _persistToken(token);
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final tokenKey = _tokenPrefsKey(user?.uid);
    final saved = prefs.getString(tokenKey);
    if (user != null) {
      await UserRepository.ensure().updateUserFields(
        user.uid,
        {"fcmToken": token},
      );
    }

    if (token != saved) {
      await prefs.setString(tokenKey, token);
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false);
  }

  Future<void> _configureForegroundPresentation() async {
    if (!_shouldUseLocalNotifications()) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_inited) return;
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Önemli bildirimler için kanal.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification_small');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    _inited = true;
  }

  Future<void> showNotification(RemoteMessage msg) async {
    if (!_shouldUseLocalNotifications()) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final fromUserID = (msg.data['fromUserID'] ?? '').toString().trim();
    if (currentUid.isNotEmpty &&
        fromUserID.isNotEmpty &&
        fromUserID == currentUid) {
      return;
    }

    final notif = msg.notification;
    final type = (msg.data['type'] ?? '').toString();
    final title = (notif?.title ?? msg.data['title'] ?? 'TurqApp').toString();
    final body = (notif?.body ?? msg.data['body'] ?? '').toString();
    if (!NotificationPreferencesService.isTypeEnabled(type,
        await NotificationPreferencesService.getCurrentUserPreferences())) {
      return;
    }
    if (title.isNotEmpty || body.isNotEmpty) {
      final imageUrl = (msg.data['imageUrl'] ?? '').toString();
      AndroidBitmap<Object>? largeIcon;
      if (imageUrl.isNotEmpty) {
        final bitmap = await _fetchImageBitmap(imageUrl);
        if (bitmap != null) largeIcon = bitmap;
      }
      await _localNotifications.show(
        id: Object.hash(title, body, type),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Önemli bildirimler için kanal.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification_small',
            color: const Color(0xFF4F718E),
            largeIcon: largeIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(msg.data),
      );
    }
  }

  Future<ByteArrayAndroidBitmap?> _fetchImageBitmap(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  void _setupMessageHandlers() {
    _foregroundMessageSub ??= FirebaseMessaging.onMessage.listen((msg) async {
      if (_shouldUseLocalNotifications()) {
        await showNotification(msg);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleData(msg.data);
    });
    _messaging.getInitialMessage().then((msg) {
      if (msg != null) _handleData(msg.data);
    });
  }

  void _onLocalNotificationTap(NotificationResponse resp) {
    if (resp.payload != null) {
      final data = jsonDecode(resp.payload!);
      _handleData(Map<String, dynamic>.from(data));
    }
  }

  void _handleData(Map<String, dynamic> data) {
    final docID = data['docID'] ?? '';
    final type = data['type'] ?? '';
    if (docID.toString().trim().isEmpty || _isHandlingTap) return;
    _isHandlingTap = true;

    Future<void>.delayed(Duration.zero, () async {
      if (navigatorKey.currentState == null) {
        _isHandlingTap = false;
        return;
      }

      navigatorKey.currentState!.push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const _NotificationOpeningOverlay(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      final controller = Get.isRegistered<NotifyReaderController>()
          ? Get.find<NotifyReaderController>()
          : Get.put(NotifyReaderController());

      final normalized = type.toString().trim().toLowerCase();
      try {
        if (normalized == "user" || normalized == "follow") {
          await controller.goToProfile(docID.toString());
          return;
        }
        if (normalized == "posts" ||
            normalized == "like" ||
            normalized == "reshared_posts" ||
            normalized == "shared_as_posts") {
          await controller.goToPost(docID.toString());
          return;
        }
        if (normalized == "comment") {
          await controller.goToPostComments(docID.toString());
          return;
        }
        if (normalized == "job_application") {
          await controller.goToJob(docID.toString());
          return;
        }
        if (normalized == "tutoring_application" ||
            normalized == "tutoring_status") {
          await controller.goToTutoring(docID.toString());
          return;
        }
        if (normalized == "chat" || normalized == "message") {
          await controller.goToChat(docID.toString());
        }
      } finally {
        _isHandlingTap = false;
      }
    });
  }

  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    required String docID,
    required String type,
    String? targetUserID,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fromUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (fromUid.isEmpty) return;
      final myToken = prefs.getString(_tokenPrefsKey(fromUid));

      final targetUid = (targetUserID != null && targetUserID.trim().isNotEmpty)
          ? targetUserID.trim()
          : (token.trim().isEmpty ? null : await _resolveUserIdByToken(token));
      if (targetUid == null || targetUid.isEmpty) return;
      if (targetUid == fromUid) return;
      if (token.trim().isNotEmpty &&
          myToken != null &&
          token.trim() == myToken) {
        return;
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(targetUid)
          .collection("notifications")
          .add({
        "type": type,
        "fromUserID": fromUid,
        "postID": docID,
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "read": false,
        "title": title,
        "body": body,
      });
    } catch (e) {
      debugPrint('Bildirim gönderme hatası: $e');
    }
  }

  Future<String?> _resolveUserIdByToken(String token) async {
    try {
      return await UserRepository.ensure().findUserIdByFcmToken(token);
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _authStateSub?.cancel();
    await _foregroundMessageSub?.cancel();
    _tokenRefreshSub = null;
    _authStateSub = null;
    _foregroundMessageSub = null;
  }

  String _tokenPrefsKey(String? uid) {
    return userScopedKey(_fcmTokenKeyPrefix, uid: uid, guestFallback: '');
  }
}

class _NotificationOpeningOverlay extends StatelessWidget {
  const _NotificationOpeningOverlay();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
