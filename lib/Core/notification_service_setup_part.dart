part of 'notification_service.dart';

extension NotificationServiceSetupPart on NotificationService {
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
    await _ensureApplePushBridgeReady();
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _persistToken(token);
  }

  Future<void> _ensureApplePushBridgeReady() async {
    if (kIsWeb || !Platform.isIOS) return;
    for (var i = 0; i < 12; i++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.isEmpty) return;

    final currentUid = _currentUid;
    final tokenKey = _tokenPrefsKey(currentUid);
    final saved = prefs.getString(tokenKey);
    if (currentUid.isNotEmpty) {
      await UserRepository.ensure().updateUserFields(
        currentUid,
        {"fcmToken": token},
      );
    }

    if (token != saved) {
      await prefs.setString(tokenKey, token);
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
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
}
