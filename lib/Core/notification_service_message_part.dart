part of 'notification_service.dart';

extension NotificationServiceMessagePart on NotificationService {
  Future<void> showNotification(RemoteMessage msg) async {
    if (!_shouldUseLocalNotifications()) return;
    final currentUid = _currentUid;
    final fromUserID = (msg.data['fromUserID'] ?? '').toString().trim();
    if (currentUid.isNotEmpty &&
        fromUserID.isNotEmpty &&
        fromUserID == currentUid) {
      return;
    }

    final notif = msg.notification;
    final type = (msg.data['type'] ?? '').toString();
    final title =
        (notif?.title ?? msg.data['title'] ?? 'app.name'.tr).toString();
    final body = (notif?.body ?? msg.data['body'] ?? '').toString();
    if (!NotificationPreferencesService.isTypeEnabled(
      type,
      await NotificationPreferencesService.getCurrentUserPreferences(),
    )) {
      return;
    }
    if (title.isNotEmpty || body.isNotEmpty) {
      final imageUrl = _notificationImageUrlFromPayload(msg.data);
      AndroidBitmap<Object>? largeIcon;
      StyleInformation? styleInformation;
      if (imageUrl.isNotEmpty) {
        final bitmap = await _fetchImageBitmap(imageUrl);
        if (bitmap != null) {
          largeIcon = bitmap;
          styleInformation = BigPictureStyleInformation(
            bitmap,
            largeIcon: bitmap,
            contentTitle: title,
            summaryText: body,
          );
        }
      }
      await _localNotifications.show(
        id: Object.hash(title, body, type),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Önemli Bildirimler',
            channelDescription: 'Önemli bildirimler için kanal.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification_small',
            color: const Color(0xFF4F718E),
            largeIcon: largeIcon,
            styleInformation: styleInformation,
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

  String _notificationImageUrlFromPayload(Map<String, dynamic> data) {
    final direct = (data['imageUrl'] ?? data['thumbnail'] ?? data['imageURL'])
        .toString()
        .trim();
    if (direct.isNotEmpty) return direct;
    for (final key in const [
      'avatarUrl',
      'applicantPfImage',
      'tutorImage',
      'companyLogo',
      'logo',
      'coverImageUrl',
    ]) {
      final next = (data[key] ?? '').toString().trim();
      if (next.isNotEmpty) return next;
    }
    final images = data['img'] ?? data['images'];
    if (images is Iterable) {
      for (final entry in images) {
        final next = entry.toString().trim();
        if (next.isNotEmpty) return next;
      }
    }
    return '';
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

      final controller = ensureNotifyReaderController();

      final decision = resolveNotificationTapRoute(
        type: type.toString(),
        docId: docID.toString(),
      );
      try {
        switch (decision.action) {
          case NotifyReaderRouteAction.profile:
            await controller.goToProfile(decision.targetId);
          case NotifyReaderRouteAction.post:
            await controller.goToPost(decision.targetId);
          case NotifyReaderRouteAction.postComments:
            await controller.goToPostComments(decision.targetId);
          case NotifyReaderRouteAction.job:
            await controller.goToJob(decision.targetId);
          case NotifyReaderRouteAction.tutoring:
            await controller.goToTutoring(decision.targetId);
          case NotifyReaderRouteAction.market:
            await controller.goToMarket(decision.targetId);
          case NotifyReaderRouteAction.chat:
            await controller.goToChat(decision.targetId);
          case NotifyReaderRouteAction.missing:
            break;
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
      final preferences = ensureLocalPreferenceRepository();
      final fromUid = _currentUid;
      if (fromUid.isEmpty) return;
      final myToken = await preferences.getString(_tokenPrefsKey(fromUid));

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

      await NotificationsRepository.ensure().createInboxItem(targetUid, {
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
}
