import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_route_decision.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_firebase_auth.dart';
import 'package:turqappv2/Core/Services/app_firebase_messaging.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../main.dart'; // navigatorKey için
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'NotifyReader/notify_reader_controller.dart';

part 'notification_service_message_part.dart';
part 'notification_service_setup_part.dart';

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
  static NotificationService? _instance;
  static NotificationService? maybeFind() => _instance;

  static NotificationService ensure() =>
      maybeFind() ?? (_instance = NotificationService._());

  static NotificationService get instance => ensure();

  final FirebaseMessaging _messaging = AppFirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;
  bool _initialized = false;
  Future<void>? _initializingFuture;
  Timer? _deferredInitializeTimer;
  static bool _bgRegistered = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authStateSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  bool _isHandlingTap = false;

  static const String _fcmTokenKeyPrefix = 'fcm_token';

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Future<void> initialize() async {
    if (_initialized) return;
    final inFlight = _initializingFuture;
    if (inFlight != null) return inFlight;
    final future = _performInitialize();
    _initializingFuture = future;
    return future;
  }

  void scheduleInitialize({
    Duration delay = const Duration(seconds: 2),
  }) {
    if (_initialized || _initializingFuture != null) return;
    _deferredInitializeTimer?.cancel();
    _deferredInitializeTimer = Timer(delay, () {
      _deferredInitializeTimer = null;
      unawaited(initialize());
    });
  }

  Future<void> _performInitialize() async {
    if (!_bgRegistered) {
      AppFirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      _bgRegistered = true;
    }
    try {
      await _requestPermission();
      await _configureForegroundPresentation();
      await setupFlutterNotifications();
      _bindTokenSyncListeners();
      await _syncCurrentToken();
      _setupMessageHandlers();
      _initialized = true;
    } finally {
      _initializingFuture = null;
    }
  }

  Future<void> dispose() async {
    _deferredInitializeTimer?.cancel();
    _deferredInitializeTimer = null;
    await _tokenRefreshSub?.cancel();
    await _authStateSub?.cancel();
    await _foregroundMessageSub?.cancel();
    _tokenRefreshSub = null;
    _authStateSub = null;
    _foregroundMessageSub = null;
    _initializingFuture = null;
    _initialized = false;
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
