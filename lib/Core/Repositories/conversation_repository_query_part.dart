part of 'conversation_repository.dart';

extension ConversationRepositoryQueryPart on ConversationRepository {
  Future<Map<String, bool>> fetchArchiveOverrides(
    String uid, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    try {
      final query =
          _firestore.collection("users").doc(uid).collection("chatArchives");
      final snap = await _getWithCachePreference(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final map = <String, bool>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = (data["userID"] ?? "").toString();
        if (userId.isEmpty) continue;
        map[userId] = data["archived"] == true;
      }
      return map;
    } catch (_) {
      return <String, bool>{};
    }
  }

  Future<Map<String, int>> fetchDeletedOverrides(
    String uid, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    try {
      final query =
          _firestore.collection("users").doc(uid).collection("chatDeletions");
      final snap = await _getWithCachePreference(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final map = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = (data["userID"] ?? "").toString();
        if (userId.isEmpty) continue;
        final rawDeletedAt = data["deletedAt"];
        final deletedAt = rawDeletedAt is num
            ? rawDeletedAt.toInt()
            : int.tryParse("$rawDeletedAt") ?? 0;
        if (deletedAt > 0) {
          map[userId] = deletedAt;
        }
      }
      return map;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchUserConversations(
    String uid, {
    required bool preferCache,
    required bool cacheOnly,
    bool includeLegacy = true,
  }) async {
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    Future<void> mergeQuery(Query<Map<String, dynamic>> query) async {
      try {
        final snap = await _getWithCachePreference(
          query,
          preferCache: preferCache,
          cacheOnly: cacheOnly,
        );
        for (final doc in snap.docs) {
          docsById[doc.id] = doc;
        }
      } catch (_) {}
    }

    await mergeQuery(
      _firestore.collection("conversations").where(
            "participants",
            arrayContains: uid,
          ),
    );

    if (includeLegacy) {
      await mergeQuery(
        _firestore.collection("conversations").where(
              "userID1",
              isEqualTo: uid,
            ),
      );
      await mergeQuery(
        _firestore.collection("conversations").where(
              "userID2",
              isEqualTo: uid,
            ),
      );
    }

    return docsById.values.toList(growable: false);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserConversations(
      String uid) {
    return _firestore
        .collection("conversations")
        .where("participants", arrayContains: uid)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConversation(
    String chatId,
  ) {
    return _firestore.collection("conversations").doc(chatId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchConversationMessagesHead(
    String chatId, {
    required int limit,
    bool cacheOnly = false,
  }) {
    final source = cacheOnly ? ListenSource.cache : ListenSource.defaultSource;
    return _firestore
        .collection("conversations")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdDate", descending: true)
        .limit(limit)
        .snapshots(source: source);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchLatestMessages(
    String chatId, {
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) {
    final query = _firestore
        .collection("conversations")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdDate", descending: true)
        .limit(limit);
    return _getWithCachePreference(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchMessagesAfter(
    String chatId, {
    required int createdAfterMs,
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) {
    final query = _firestore
        .collection("conversations")
        .doc(chatId)
        .collection("messages")
        .where("createdDate", isGreaterThan: createdAfterMs)
        .orderBy("createdDate", descending: false)
        .limit(limit);
    return _getWithCachePreference(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchOlderMessages(
    String chatId, {
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) {
    final query = _firestore
        .collection("conversations")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdDate", descending: true)
        .startAfterDocument(startAfter)
        .limit(limit);
    return _getWithCachePreference(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }
}
