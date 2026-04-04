part of 'in_app_notifications_controller.dart';

extension InAppNotificationsControllerActionsPart
    on InAppNotificationsController {
  void _queueMarkAllAsReadIfNeeded() {
    if (_markAllReadQueued || busyMarkAllRead.value) return;
    if (_allNotifications.every((n) => n.isRead)) return;
    _markAllReadQueued = true;
    Future<void>.microtask(() async {
      try {
        await markAllAsRead();
      } finally {
        _markAllReadQueued = false;
      }
    });
  }

  void markInboxSeen() {
    if (_inboxSeenRequested) {
      _queueMarkAllAsReadIfNeeded();
      return;
    }
    _inboxSeenRequested = true;
    _queueMarkAllAsReadIfNeeded();
  }

  Future<void> delete(String docID) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final previousAll = List<NotificationModel>.from(_allNotifications);
    _allNotifications.removeWhere((n) => n.docID == docID);
    _applyFilters();
    _refreshUnreadTotal();
    await _notificationsSnapshotRepository.deleteLocally(
      userId: uid,
      docIds: <String>[docID],
    );
    try {
      await _notificationsRepository.delete(uid, docID);
    } catch (_) {
      _allNotifications
        ..clear()
        ..addAll(previousAll);
      _applyFilters();
      _refreshUnreadTotal();
      unawaited(_notificationsSnapshotRepository.persistInboxSnapshot(
        userId: uid,
        notifications: previousAll,
        source: CachedResourceSource.scopedDisk,
      ));
      rethrow;
    }
  }

  Future<void> deleteMany(List<String> docIDs) async {
    if (docIDs.isEmpty) return;
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final uniqueIds = docIDs.toSet().toList(growable: false);

    final previousAll = List<NotificationModel>.from(_allNotifications);
    _allNotifications.removeWhere((n) => uniqueIds.contains(n.docID));
    _applyFilters();
    _refreshUnreadTotal();
    await _notificationsSnapshotRepository.deleteLocally(
      userId: uid,
      docIds: uniqueIds,
    );
    try {
      await _notificationsRepository.deleteMany(uid, uniqueIds);
    } catch (_) {
      _allNotifications
        ..clear()
        ..addAll(previousAll);
      _applyFilters();
      _refreshUnreadTotal();
      unawaited(_notificationsSnapshotRepository.persistInboxSnapshot(
        userId: uid,
        notifications: previousAll,
        source: CachedResourceSource.scopedDisk,
      ));
      rethrow;
    }
  }

  Future<void> markAsRead(String docID) async {
    final idx = _allNotifications.indexWhere((n) => n.docID == docID);
    if (idx < 0 || _allNotifications[idx].isRead) return;

    final uid = _currentUid;
    if (uid.isEmpty) return;
    _allNotifications[idx].isRead = true;
    _applyFilters();
    _refreshUnreadTotal();
    await _notificationsSnapshotRepository.markReadLocally(
      userId: uid,
      docIds: <String>[docID],
    );

    try {
      await _notificationsRepository.markRead(uid, docID);
      _refreshUnreadTotal();
    } catch (_) {
      _allNotifications[idx].isRead = false;
      _applyFilters();
      _refreshUnreadTotal();
      unawaited(_notificationsSnapshotRepository.persistInboxSnapshot(
        userId: uid,
        notifications: List<NotificationModel>.from(_allNotifications),
        source: CachedResourceSource.scopedDisk,
      ));
    }
  }

  Future<void> markManyAsRead(List<String> docIDs) async {
    if (docIDs.isEmpty) return;
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final uniqueIds = docIDs.toSet().toList(growable: false);

    final changed = <int>[];
    for (var i = 0; i < _allNotifications.length; i++) {
      if (!uniqueIds.contains(_allNotifications[i].docID) ||
          _allNotifications[i].isRead) {
        continue;
      }
      _allNotifications[i].isRead = true;
      changed.add(i);
    }
    if (changed.isNotEmpty) {
      _applyFilters();
      _refreshUnreadTotal();
      await _notificationsSnapshotRepository.markReadLocally(
        userId: uid,
        docIds: uniqueIds,
      );
    }

    try {
      await _notificationsRepository.markManyRead(uid, uniqueIds);
    } catch (_) {
      for (final idx in changed) {
        _allNotifications[idx].isRead = false;
      }
      if (changed.isNotEmpty) {
        _applyFilters();
        _refreshUnreadTotal();
        unawaited(_notificationsSnapshotRepository.persistInboxSnapshot(
          userId: uid,
          notifications: List<NotificationModel>.from(_allNotifications),
          source: CachedResourceSource.scopedDisk,
        ));
      }
    }
  }

  void markChatNotificationsReadLocal({required String chatId}) {
    final targetChatId = chatId.trim();
    if (targetChatId.isEmpty) return;

    final toMarkIds = <String>[];
    for (final item in _allNotifications) {
      if (item.isRead) continue;
      final normalizedType =
          normalizeLowercase(item.type.isNotEmpty ? item.type : item.postType);
      final isChatType =
          normalizedType == 'chat' || normalizedType == 'message';
      if (!isChatType) continue;
      if (item.postID != targetChatId) continue;
      item.isRead = true;
      toMarkIds.add(item.docID);
    }

    if (toMarkIds.isEmpty) return;
    list.refresh();
    _refreshUnreadTotal();
    unawaited(markManyAsRead(toMarkIds));
  }

  Future<void> markAllAsRead() async {
    if (busyMarkAllRead.value) return;
    final uid = _currentUid;
    if (uid.isEmpty) return;
    busyMarkAllRead.value = true;
    final unread = list
        .where((n) => !n.isRead)
        .map((n) => n.docID)
        .toList(growable: false);
    if (unread.isEmpty) {
      busyMarkAllRead.value = false;
      return;
    }

    try {
      await _notificationsRepository.markManyRead(uid, unread);
      for (final item in _allNotifications) {
        item.isRead = true;
      }
      _applyFilters();
      _refreshUnreadTotal();
      await _notificationsSnapshotRepository.markReadLocally(
        userId: uid,
        docIds: unread,
      );
    } finally {
      busyMarkAllRead.value = false;
    }
  }

  Future<void> bildirimleriTopluSil() async {
    final uid = _currentUid;
    if (uid.isEmpty || _suppressRemoteInboxSync) return;
    final previousAll = List<NotificationModel>.from(_allNotifications);
    _suppressRemoteInboxSync = true;
    _clearNotificationState();
    await _notificationsSnapshotRepository.persistInboxSnapshot(
      userId: uid,
      notifications: const <NotificationModel>[],
      source: CachedResourceSource.scopedDisk,
    );
    try {
      await _notificationsRepository.deleteAll(uid);
      await _refreshNotificationsSnapshot(uid);
    } catch (_) {
      _allNotifications
        ..clear()
        ..addAll(previousAll);
      _applyFilters();
      _refreshUnreadTotal();
      unawaited(_notificationsSnapshotRepository.persistInboxSnapshot(
        userId: uid,
        notifications: previousAll,
        source: CachedResourceSource.scopedDisk,
      ));
      rethrow;
    } finally {
      _suppressRemoteInboxSync = false;
    }
  }

  bool isMentionNotification(NotificationModel model) {
    final desc = normalizeSearchText(model.desc);
    final title = normalizeSearchText(model.title);
    final isComment = model.postType == kNotificationPostTypeComment;
    return desc.contains('@') ||
        title.contains('@') ||
        desc.contains('etiket') ||
        title.contains('etiket') ||
        isComment;
  }

  String _descFromType(String type, {String title = ''}) {
    final key = notificationDescriptionKeyForType(type);
    return key.isEmpty ? '' : key.tr;
  }
}
