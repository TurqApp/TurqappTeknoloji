import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

class NotificationsSnapshotQuery {
  const NotificationsSnapshotQuery({
    required this.userId,
    this.limit = 300,
    this.scopeTag = 'inbox',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}

class NotificationsSnapshotRepository extends GetxService {
  NotificationsSnapshotRepository();

  static const String _surfaceKey = 'notifications_inbox_snapshot';

  static NotificationsSnapshotRepository ensure() {
    if (Get.isRegistered<NotificationsSnapshotRepository>()) {
      return Get.find<NotificationsSnapshotRepository>();
    }
    return Get.put(NotificationsSnapshotRepository(), permanent: true);
  }

  final NotificationsRepository _notificationsRepository =
      NotificationsRepository.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();

  late final CacheFirstCoordinator<List<NotificationModel>> _coordinator =
      CacheFirstCoordinator<List<NotificationModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<NotificationModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<NotificationModel>>(
      prefsPrefix: 'notifications_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<NotificationModel>>(),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 10),
      minLiveSyncInterval: Duration(seconds: 20),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );

  late final CacheFirstQueryPipeline<NotificationsSnapshotQuery,
          List<NotificationModel>, List<NotificationModel>> _pipeline =
      CacheFirstQueryPipeline<NotificationsSnapshotQuery,
          List<NotificationModel>, List<NotificationModel>>(
    surfaceKey: _surfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: _fetchServerSnapshot,
    resolve: (items) => items,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );

  Stream<CachedResource<List<NotificationModel>>> openInbox({
    required String userId,
    int limit = 300,
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
    int limit = 300,
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
    int limit = 300,
  }) {
    final query = NotificationsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    return _coordinator.bootstrap(
      ScopedSnapshotKey(
        surfaceKey: _surfaceKey,
        userId: query.userId.trim(),
        scopeId: query.scopeId,
      ),
      loadWarmSnapshot: () => _loadWarmSnapshot(query),
    );
  }

  Future<void> persistInboxSnapshot({
    required String userId,
    required List<NotificationModel> notifications,
    int limit = 300,
    CachedResourceSource source = CachedResourceSource.server,
  }) async {
    final normalized = notifications
        .where((item) => item.docID.isNotEmpty)
        .take(limit)
        .toList(growable: false);
    if (normalized.isEmpty) return;
    final query = NotificationsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    await _coordinator.snapshotStore.write(
      ScopedSnapshotKey(
        surfaceKey: _surfaceKey,
        userId: query.userId.trim(),
        scopeId: query.scopeId,
      ),
      ScopedSnapshotRecord<List<NotificationModel>>(
        data: normalized,
        snapshotAt: DateTime.now(),
        schemaVersion: 1,
        generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
        source: source,
      ),
    );
    await _coordinator.memoryStore.write(
      ScopedSnapshotKey(
        surfaceKey: _surfaceKey,
        userId: query.userId.trim(),
        scopeId: query.scopeId,
      ),
      ScopedSnapshotRecord<List<NotificationModel>>(
        data: normalized,
        snapshotAt: DateTime.now(),
        schemaVersion: 1,
        generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
        source: source,
      ),
    );
  }

  Future<void> markReadLocally({
    required String userId,
    required List<String> docIds,
    int limit = 300,
  }) async {
    if (userId.trim().isEmpty || docIds.isEmpty) return;
    final current = await bootstrapInbox(
      userId: userId,
      limit: limit,
    );
    final items = current.data;
    if (items == null || items.isEmpty) return;
    final wanted = docIds.toSet();
    final updated = items
        .map((item) => wanted.contains(item.docID)
            ? NotificationModel(
                docID: item.docID,
                desc: item.desc,
                isRead: true,
                type: item.type,
                postID: item.postID,
                postType: item.postType,
                thumbnail: item.thumbnail,
                timeStamp: item.timeStamp,
                title: item.title,
                userID: item.userID,
              )
            : item)
        .toList(growable: false);
    final matchedCount =
        items.where((item) => wanted.contains(item.docID)).length;
    await persistInboxSnapshot(
      userId: userId,
      notifications: updated,
      limit: limit,
      source: CachedResourceSource.scopedDisk,
    );
    _invariantGuard.assertNotEmptyAfterRefresh(
      surface: 'notifications',
      invariantKey: 'optimistic_mark_read_preserve_snapshot',
      hadSnapshot: items.isNotEmpty,
      previousCount: items.length,
      nextCount: updated.length,
      payload: <String, dynamic>{
        'userId': userId,
        'matchedCount': matchedCount,
        'requestedCount': wanted.length,
      },
    );
    _invariantGuard.assertMutationMatched(
      surface: 'notifications',
      invariantKey: 'optimistic_mark_read_matched_none',
      requestedCount: wanted.length,
      matchedCount: matchedCount,
      mutationName: 'markRead',
      payload: <String, dynamic>{
        'userId': userId,
      },
    );
  }

  Future<void> deleteLocally({
    required String userId,
    required List<String> docIds,
    int limit = 300,
  }) async {
    if (userId.trim().isEmpty || docIds.isEmpty) return;
    final current = await bootstrapInbox(
      userId: userId,
      limit: limit,
    );
    final items = current.data;
    if (items == null || items.isEmpty) return;
    final wanted = docIds.toSet();
    final updated = items
        .where((item) => !wanted.contains(item.docID))
        .toList(growable: false);
    final removedCount = items.length - updated.length;
    await persistInboxSnapshot(
      userId: userId,
      notifications: updated,
      limit: limit,
      source: CachedResourceSource.scopedDisk,
    );
    if (removedCount > wanted.length) {
      _invariantGuard.record(
        surface: 'notifications',
        invariantKey: 'optimistic_delete_removed_too_many',
        message: 'Optimistic delete removed more notifications than requested',
        payload: <String, dynamic>{
          'userId': userId,
          'removedCount': removedCount,
          'requestedCount': wanted.length,
          'previousCount': items.length,
          'nextCount': updated.length,
        },
      );
    }
    _invariantGuard.assertMutationMatched(
      surface: 'notifications',
      invariantKey: 'optimistic_delete_matched_none',
      requestedCount: wanted.length,
      matchedCount: removedCount,
      mutationName: 'delete',
      payload: <String, dynamic>{
        'userId': userId,
        'previousCount': items.length,
      },
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
          postType: _postTypeFromType((data['type'] ?? '').toString()),
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

  String _postTypeFromType(String type) {
    switch (type) {
      case 'follow':
      case kNotificationPostTypeUser:
        return kNotificationPostTypeUser;
      case 'comment':
      case kNotificationPostTypeComment:
        return kNotificationPostTypeComment;
      case 'message':
      case kNotificationPostTypeChat:
        return kNotificationPostTypeChat;
      case 'job_application':
        return kNotificationPostTypeJobApplication;
      case 'tutoring_application':
      case 'tutoring_status':
        return kNotificationPostTypeTutoringApplication;
      case 'like':
      case 'reshared_posts':
      case 'shared_as_posts':
      case 'reshare':
      case kNotificationPostTypePosts:
      default:
        return kNotificationPostTypePosts;
    }
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
