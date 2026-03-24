part of 'notifications_snapshot_repository.dart';

extension NotificationsSnapshotRepositoryQueryPart
    on NotificationsSnapshotRepository {
  Stream<CachedResource<List<NotificationModel>>> openInbox({
    required String userId,
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
    bool forceSync = false,
  }) {
    return _pipeline.open(
      NotificationsSnapshotQuery(
        userId: userId,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<NotificationModel>>> loadInbox({
    required String userId,
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
    bool forceSync = false,
  }) {
    return openInbox(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<CachedResource<List<NotificationModel>>> bootstrapInbox({
    required String userId,
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
  }) {
    final query = NotificationsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    return _coordinator.bootstrap(
      ScopedSnapshotKey(
        surfaceKey: NotificationsSnapshotRepository._surfaceKey,
        userId: query.userId.trim(),
        scopeId: query.scopeId,
      ),
      loadWarmSnapshot: () => _loadWarmSnapshot(query),
    );
  }

  Future<List<NotificationModel>> _fetchServerSnapshot(
    NotificationsSnapshotQuery query,
  ) async {
    final snapshot = await _notificationsRepository.fetchServerNotifications(
      query.userId,
      limit: query.limit,
    );
    return _mapNotificationDocs(snapshot.docs);
  }

  Future<List<NotificationModel>?> _loadWarmSnapshot(
    NotificationsSnapshotQuery query,
  ) async {
    final snapshot = await _notificationsRepository.fetchCachedNotifications(
      query.userId,
      limit: query.limit,
    );
    final notifications = _mapNotificationDocs(snapshot.docs);
    return notifications.isEmpty ? null : notifications;
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
        return NotificationModel(
          docID: doc.id,
          isRead: (data['isRead'] ?? data['read'] ?? false) == true,
          type: (data['type'] ?? '').toString(),
          postID: (data['postID'] ?? '').toString(),
          postType: notificationPostTypeFromEventType(
              (data['type'] ?? '').toString()),
          thumbnail: (data['thumbnail'] ?? '').toString(),
          timeStamp: _asInt(data['timeStamp']),
          title: (data['title'] ?? '').toString(),
          userID: (data['fromUserID'] ?? '').toString(),
          desc: (data['body'] ?? data['desc'] ?? '').toString(),
        );
      }
      return NotificationModel.fromJson(data, doc.id);
    }).toList(growable: false);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Map<String, dynamic> _encodeItems(List<NotificationModel> items) {
    return <String, dynamic>{
      'items': items
          .map((item) => <String, dynamic>{
                'docID': item.docID,
                ...item.toJson(),
              })
          .toList(growable: false),
    };
  }

  List<NotificationModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          final docId = (item.remove('docID') ?? '').toString();
          return NotificationModel.fromJson(item, docId);
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }
}
