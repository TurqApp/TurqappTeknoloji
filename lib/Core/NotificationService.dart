import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // navigatorKey için
import 'NotifyReader/NotifyReader.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
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

  Future<void> initialize() async {
    if (!_bgRegistered) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      _bgRegistered = true;
    }
    await _requestPermission();
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
    final saved = prefs.getString('fcm_token');
    if (token.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
        {"token": token, "fcmToken": token, "fcm_token": token},
        SetOptions(merge: true),
      );
    }

    if (token != saved) {
      await prefs.setString('fcm_token', token);
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false);
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
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    final notif = msg.notification;
    final android = msg.notification?.android;
    if (notif != null && android != null) {
      await _localNotifications.show(
        id: notif.hashCode,
        title: notif.title,
        body: notif.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Önemli bildirimler için kanal.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
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

  void _setupMessageHandlers() {
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
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => NotifyReader(docID: docID, type: type),
    ));
  }

  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    required String docID,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final myToken = prefs.getString('fcm_token');
      if (token.isEmpty || token == myToken || myToken == null) return;

      final targetUid = await _resolveUserIdByToken(token);
      if (targetUid == null || targetUid.isEmpty) return;

      final fromUid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
      final byToken = await FirebaseFirestore.instance
          .collection("users")
          .where("token", isEqualTo: token)
          .limit(1)
          .get();
      if (byToken.docs.isNotEmpty) return byToken.docs.first.id;

      final byFcmToken = await FirebaseFirestore.instance
          .collection("users")
          .where("fcmToken", isEqualTo: token)
          .limit(1)
          .get();
      if (byFcmToken.docs.isNotEmpty) return byFcmToken.docs.first.id;

      final byFcmTokenSnake = await FirebaseFirestore.instance
          .collection("users")
          .where("fcm_token", isEqualTo: token)
          .limit(1)
          .get();
      if (byFcmTokenSnake.docs.isNotEmpty) return byFcmTokenSnake.docs.first.id;

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _authStateSub?.cancel();
    _tokenRefreshSub = null;
    _authStateSub = null;
  }
}
