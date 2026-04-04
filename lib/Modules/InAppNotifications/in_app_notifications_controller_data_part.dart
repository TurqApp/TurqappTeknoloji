part of 'in_app_notifications_controller.dart';

extension InAppNotificationsControllerDataPart on InAppNotificationsController {
  bool _isIgnorablePermissionDenied(Object error) {
    return IntegrationTestMode.enabled &&
        error is FirebaseException &&
        error.code == 'permission-denied';
  }

  void _bindPreferences() {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _settingsSub?.cancel();
    _settingsSub =
        _notificationsRepository.watchSettings(uid).listen((snapshot) {
      _preferences =
          NotificationPreferencesService.mergeWithDefaults(snapshot.data());
      _applyFilters();
    }, onError: (error) {
      if (_isIgnorablePermissionDenied(error)) {
        return;
      }
      debugPrint('🔔 InApp notification settings listener error: $error');
    });
  }

  Future<void> getData() async {
    final uid = _currentUid;
    _notificationSub?.cancel();
    _newNotificationHeadSub?.cancel();
    if (uid.isEmpty) {
      _clearNotificationState();
      return;
    }

    await _loadInitialNotificationsFromSnapshot(uid);
    _bindNotificationsCacheStream(uid);
    _bindNewNotificationHeadStream(uid);
    unawaited(_refreshNotificationsSnapshot(uid));
  }

  Future<void> _loadInitialNotificationsFromSnapshot(String uid) async {
    try {
      final resource = await _notificationsSnapshotRepository.bootstrapInbox(
        userId: uid,
      );
      _applySnapshotResource(resource);
    } catch (_) {
      complatedDataFetch.value = true;
    }
  }

  Future<void> _refreshNotificationsSnapshot(String uid) async {
    try {
      final resource = await _notificationsSnapshotRepository.loadInbox(
        userId: uid,
        forceSync: true,
      );
      _applySnapshotResource(resource);
    } catch (_) {}
  }

  void _bindNotificationsCacheStream(String uid) {
    _notificationSub = _notificationsRepository
        .watchCachedNotifications(uid)
        .listen((snapshot) {
      if (_suppressRemoteInboxSync) return;
      _applyNotificationDocs(snapshot.docs, replace: true);
    }, onError: (error) {
      complatedDataFetch.value = true;
      if (_isIgnorablePermissionDenied(error)) {
        return;
      }
      debugPrint('🔔 InApp notifications listener error: $error');
    });
  }

  void _bindNewNotificationHeadStream(String uid) {
    _newNotificationHeadSub =
        _notificationsRepository.watchNotificationHead(uid).listen((snapshot) {
      if (_suppressRemoteInboxSync) return;
      if (snapshot.docs.isEmpty) return;
      final headData = snapshot.docs.first.data();
      final headTs = _asInt(headData['timeStamp']);
      if (headTs > _latestLoadedNotificationTs()) {
        unawaited(_fetchOnlyNewNotifications(uid));
      }
    }, onError: (_) {});
  }

  Future<void> _fetchOnlyNewNotifications(String uid) async {
    if (_suppressRemoteInboxSync) return;
    try {
      final latestTs = _latestLoadedNotificationTs();
      final snapshot = await _notificationsRepository.fetchOnlyNewNotifications(
        uid,
        latestTs: latestTs,
      );
      if (_suppressRemoteInboxSync) return;
      _applyNotificationDocs(snapshot.docs, replace: false);
    } catch (_) {}
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  int _latestLoadedNotificationTs() {
    var latest = 0;
    for (final n in _allNotifications) {
      final ts = _asInt(n.timeStamp);
      if (ts > latest) latest = ts;
    }
    return latest;
  }

  List<NotificationModel> _mapNotificationDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final hideByFlag = data['hideInAppInbox'] == true;
      final hideByLegacyPostId =
          (data['postID'] ?? '').toString() == 'admin-manual-push';
      return !hideByFlag && !hideByLegacyPostId;
    }).map((doc) {
      final data = doc.data();

      if (data.containsKey('type') || data.containsKey('fromUserID')) {
        final type = (data['type'] ?? '').toString();
        final postType = notificationPostTypeFromEventType(type);
        final title = (data['title'] ?? '').toString();
        final body = (data['body'] ?? '').toString();

        return NotificationModel(
          docID: doc.id,
          isRead: (data['isRead'] ?? data['read'] ?? false) == true,
          type: type,
          postID: (data['postID'] ?? '').toString(),
          postType: postType,
          thumbnail: (data['thumbnail'] ?? '').toString(),
          timeStamp: _asInt(data['timeStamp']),
          title: title,
          userID: (data['fromUserID'] ?? '').toString(),
          desc: body.isNotEmpty ? body : _descFromType(type, title: title),
        );
      }

      return NotificationModel.fromJson(data, doc.id);
    }).toList();
  }

  void _applyNotificationDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool replace,
  }) {
    if (_suppressRemoteInboxSync) return;
    final mapped = _mapNotificationDocs(docs);
    if (replace) {
      _allNotifications
        ..clear()
        ..addAll(mapped);
    } else {
      final merged = <String, NotificationModel>{
        for (final item in _allNotifications) item.docID: item,
      };
      for (final item in mapped) {
        merged[item.docID] = item;
      }
      final next = merged.values.toList(growable: false)
        ..sort((a, b) => _asInt(b.timeStamp).compareTo(_asInt(a.timeStamp)));
      _allNotifications
        ..clear()
        ..addAll(next);
    }
    complatedDataFetch.value = true;
    _applyFilters();
    _refreshUnreadTotal();
    final uid = _currentUid;
    if (uid.isNotEmpty) {
      unawaited(_notificationsSnapshotRepository.persistInboxSnapshot(
        userId: uid,
        notifications: List<NotificationModel>.from(_allNotifications),
        source: CachedResourceSource.firestoreCache,
      ));
    }
  }

  void _applySnapshotResource(
    CachedResource<List<NotificationModel>> resource,
  ) {
    final notifications = resource.data;
    if (notifications == null || notifications.isEmpty) {
      _clearNotificationState();
      return;
    }
    _allNotifications
      ..clear()
      ..addAll(notifications);
    complatedDataFetch.value = true;
    _applyFilters();
    _refreshUnreadTotal();
  }

  void _applyFilters() {
    list.value = _allNotifications
        .where((notification) => NotificationPreferencesService.isTypeEnabled(
              notification.type.isEmpty
                  ? notification.postType
                  : notification.type,
              _preferences,
            ))
        .toList(growable: false);
    _refreshUnreadTotal();
  }

  void _refreshUnreadTotal() {
    unreadTotal.value = _allNotifications.where((n) => !n.isRead).length;
  }

  void _clearNotificationState() {
    _allNotifications.clear();
    list.clear();
    unreadTotal.value = 0;
    complatedDataFetch.value = true;
  }
}
