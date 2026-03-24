part of 'notifications_snapshot_repository.dart';

extension NotificationsSnapshotRepositoryActionPart
    on NotificationsSnapshotRepository {
  Future<void> persistInboxSnapshot({
    required String userId,
    required List<NotificationModel> notifications,
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
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
        surfaceKey: NotificationsSnapshotRepository._surfaceKey,
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
        surfaceKey: NotificationsSnapshotRepository._surfaceKey,
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
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
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
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
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
}
