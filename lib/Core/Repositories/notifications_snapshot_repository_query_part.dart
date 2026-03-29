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
        surfaceKey: _notificationsInboxSnapshotSurfaceKey,
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
      final hideByFlag = _asBool(data['hideInAppInbox']);
      final hideByLegacyPostId =
          (data['postID'] ?? '').toString() == 'admin-manual-push';
      return !hideByFlag && !hideByLegacyPostId;
    }).map((doc) {
      final data = doc.data();
      if (data.containsKey('type') || data.containsKey('fromUserID')) {
        return NotificationModel(
          docID: doc.id,
          isRead: _asBool(data['isRead'] ?? data['read']),
          type: (data['type'] ?? '').toString(),
          postID: (data['postID'] ?? '').toString(),
          postType: notificationPostTypeFromEventType(
              (data['type'] ?? '').toString()),
          thumbnail:
              (data['thumbnail'] ?? data['imageUrl'] ?? data['imageURL'] ?? '')
                  .toString(),
          timeStamp: _asInt(data['timeStamp']),
          title: (data['title'] ?? '').toString(),
          userID: (data['fromUserID'] ?? '').toString(),
          desc: (data['body'] ?? data['desc'] ?? '').toString(),
        );
      }
      return NotificationModel.fromJson(data, doc.id);
    }).toList(growable: false);
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    final raw = '$value'.trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.trim();
      final parsed = int.tryParse(normalized);
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(normalized);
      if (parsedNum != null) return parsedNum.toInt();
    }
    return 0;
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
          final docId = (item.remove('docID') ?? '').toString().trim();
          return NotificationModel.fromJson(item, docId);
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }
}
