part of 'notifications_repository.dart';

extension NotificationsRepositoryRuntimeX on NotificationsRepository {
  DocumentReference<Map<String, dynamic>> postNotificationSubscriberDoc(
    String authorId,
    String subscriberUid,
  ) {
    final trimmedAuthorId = authorId.trim();
    final trimmedSubscriberUid = subscriberUid.trim();
    return _postNotificationSubscribersRef(trimmedAuthorId).doc(
      trimmedSubscriberUid,
    );
  }

  DocumentReference<Map<String, dynamic>> inboxDoc(
    String uid, {
    String? docId,
  }) {
    final trimmedUid = uid.trim();
    return docId == null || docId.trim().isEmpty
        ? _firestore
            .collection('users')
            .doc(trimmedUid)
            .collection('notifications')
            .doc()
        : _firestore
            .collection('users')
            .doc(trimmedUid)
            .collection('notifications')
            .doc(docId.trim());
  }

  void queueCreateInboxItem(
    WriteBatch batch,
    String uid,
    Map<String, dynamic> payload, {
    String? docId,
  }) {
    if (uid.trim().isEmpty || payload.isEmpty) return;
    batch.set(
      inboxDoc(uid.trim(), docId: docId),
      normalizeInboxPayload(uid, payload),
    );
  }

  Future<void> createInboxItem(
    String uid,
    Map<String, dynamic> payload,
  ) async {
    if (uid.trim().isEmpty || payload.isEmpty) return;
    await inboxDoc(uid.trim()).set(normalizeInboxPayload(uid, payload));
  }

  Future<void> subscribeToAuthorPosts(
    String authorId,
    String subscriberUid,
  ) async {
    final trimmedAuthorId = authorId.trim();
    final trimmedSubscriberUid = subscriberUid.trim();
    if (trimmedAuthorId.isEmpty || trimmedSubscriberUid.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await postNotificationSubscriberDoc(
      trimmedAuthorId,
      trimmedSubscriberUid,
    ).set({
      'subscriberId': trimmedSubscriberUid,
      'authorId': trimmedAuthorId,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> unsubscribeFromAuthorPosts(
    String authorId,
    String subscriberUid,
  ) async {
    final trimmedAuthorId = authorId.trim();
    final trimmedSubscriberUid = subscriberUid.trim();
    if (trimmedAuthorId.isEmpty || trimmedSubscriberUid.isEmpty) return;
    await postNotificationSubscriberDoc(
      trimmedAuthorId,
      trimmedSubscriberUid,
    ).delete();
  }

  Future<bool> hasAuthorPostSubscription(
    String authorId,
    String subscriberUid,
  ) async {
    final trimmedAuthorId = authorId.trim();
    final trimmedSubscriberUid = subscriberUid.trim();
    if (trimmedAuthorId.isEmpty || trimmedSubscriberUid.isEmpty) {
      return false;
    }
    final entry = await postNotificationSubscriberDoc(
      trimmedAuthorId,
      trimmedSubscriberUid,
    ).get(const GetOptions(source: Source.serverAndCache));
    return entry.exists;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSettings(String uid) {
    return _settingsRef(uid).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchCachedNotifications(
    String uid, {
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
  }) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.cache));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchServerNotifications(
    String uid, {
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
  }) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCachedNotifications(
    String uid, {
    int limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
  }) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .snapshots(source: ListenSource.cache);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotificationHead(
    String uid,
  ) {
    return _notificationsRef(uid)
        .orderBy('timeStamp', descending: true)
        .limit(1)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchOnlyNewNotifications(
    String uid, {
    required int latestTs,
    int limit = ReadBudgetRegistry.notificationsDeltaFetchLimit,
  }) {
    Query<Map<String, dynamic>> query = _notificationsRef(uid)
        .orderBy('timeStamp', descending: false)
        .limit(limit);
    if (latestTs > 0) {
      query = query.where('timeStamp', isGreaterThan: latestTs);
    }
    return query.get(const GetOptions(source: Source.server));
  }

  Future<void> delete(String uid, String docId) {
    return _notificationsRef(uid).doc(docId).delete();
  }

  Future<void> deleteMany(String uid, List<String> docIds) async {
    if (docIds.isEmpty) return;
    final uniqueIds = docIds.toSet().toList(growable: false);
    for (var i = 0; i < uniqueIds.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = uniqueIds.skip(i).take(450);
      for (final docID in chunk) {
        batch.delete(_notificationsRef(uid).doc(docID));
      }
      await batch.commit();
    }
  }

  Future<void> markRead(String uid, String docId) {
    return _notificationsRef(uid)
        .doc(docId)
        .set({'read': true, 'isRead': true}, SetOptions(merge: true));
  }

  Future<void> markManyRead(String uid, List<String> docIds) async {
    if (docIds.isEmpty) return;
    final uniqueIds = docIds.toSet().toList(growable: false);
    for (var i = 0; i < uniqueIds.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = uniqueIds.skip(i).take(450);
      for (final docID in chunk) {
        batch.set(
          _notificationsRef(uid).doc(docID),
          {'read': true, 'isRead': true},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Future<void> deleteAll(String uid) async {
    while (true) {
      final snapshot = await _notificationsRef(uid).limit(500).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
