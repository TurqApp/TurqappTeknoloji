part of 'admin_push_repository.dart';

extension AdminPushRepositoryActionPart on AdminPushRepository {
  Future<void> _deleteReportImpl(String reportId) async {
    if (reportId.isEmpty) return;
    await _reportsRef.doc(reportId).delete();
  }

  Future<void> _addReportImpl({
    required String senderUid,
    required String title,
    required String body,
    required String type,
    required int targetCount,
    required AdminPushTargetFilters filters,
  }) async {
    await _reportsRef.add({
      'senderUid': senderUid,
      'title': title,
      'body': body,
      'type': type,
      'targetCount': targetCount,
      'filters': {
        'uid': filters.uid,
        'meslek': filters.meslek,
        'konum': filters.konum,
        'cinsiyet': filters.gender,
        'minAge': filters.minAge,
        'maxAge': filters.maxAge,
      },
      'createdDate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _addPostReportImpl({
    required String senderUid,
    required String title,
    required String body,
    required int targetCount,
    required String postId,
    required String? imageUrl,
  }) async {
    await _reportsRef.add({
      'senderUid': senderUid,
      'title': title,
      'body': body,
      'type': 'posts',
      if (imageUrl != null && imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl,
      'targetCount': targetCount,
      'postID': postId,
      'createdDate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _sendPushImpl({
    required String title,
    required String body,
    required String type,
    required List<String> targetUids,
  }) async {
    if (targetUids.isEmpty) return;
    final senderUid = CurrentUserService.instance.effectiveUserId.isNotEmpty
        ? CurrentUserService.instance.effectiveUserId
        : 'admin';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const batchSize = 400;

    for (var i = 0; i < targetUids.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = targetUids.skip(i).take(batchSize);
      for (final targetUid in chunk) {
        NotificationsRepository.ensure().queueCreateInboxItem(
          batch,
          targetUid,
          {
            'type': type,
            'title': title,
            'body': body,
            'fromUserID': senderUid,
            'postID': 'admin-manual-push',
            'adminPush': true,
            'hideInAppInbox': true,
            'timeStamp': nowMs,
            'read': false,
          },
        );
      }
      await batch.commit();
    }
  }

  Future<int> _sendPostPushImpl({
    required String postId,
    required String title,
    required String body,
    required String? imageUrl,
    required AdminPushTargetFilters filters,
  }) async {
    final targetUids = await resolveTargetUids(filters: filters);
    if (targetUids.isEmpty) return 0;

    final senderUid = CurrentUserService.instance.effectiveUserId.isNotEmpty
        ? CurrentUserService.instance.effectiveUserId
        : 'admin';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const batchSize = 400;
    var written = 0;

    for (var i = 0; i < targetUids.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = targetUids.skip(i).take(batchSize);
      for (final targetUid in chunk) {
        NotificationsRepository.ensure().queueCreateInboxItem(
          batch,
          targetUid,
          {
            'type': 'posts',
            'fromUserID': senderUid,
            'postID': postId,
            if (imageUrl != null && imageUrl.trim().isNotEmpty)
              'imageUrl': imageUrl,
            'adminPush': true,
            'hideInAppInbox': true,
            'timeStamp': nowMs,
            'read': false,
            'title': title,
            'body': body,
          },
        );
        written++;
      }
      await batch.commit();
    }

    return written;
  }
}
