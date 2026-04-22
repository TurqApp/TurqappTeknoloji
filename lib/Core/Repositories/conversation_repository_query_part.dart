part of 'conversation_repository.dart';

extension ConversationRepositoryQueryPart on ConversationRepository {
  bool _asConversationBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  int _asConversationInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

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
        map[userId] = _asConversationBool(data["archived"]);
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
        final deletedAt = _asConversationInt(data["deletedAt"]);
        if (deletedAt > 0) {
          map[userId] = deletedAt;
        }
      }
      return map;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<int> fetchDeletedCutoffForConversation(
    String uid,
    String otherUserId, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedOtherUserId = otherUserId.trim();
    if (normalizedUid.isEmpty || normalizedOtherUserId.isEmpty) return 0;
    try {
      final ref = _firestore
          .collection("users")
          .doc(normalizedUid)
          .collection("chatDeletions")
          .doc(normalizedOtherUserId);
      final snap = cacheOnly
          ? await ref.get(const GetOptions(source: Source.cache))
          : preferCache
              ? await ref.get(const GetOptions(source: Source.serverAndCache))
              : await ref.get(const GetOptions(source: Source.server));
      final data = snap.data();
      if (!snap.exists || data == null || data.isEmpty) return 0;
      return _asConversationInt(data["deletedAt"]);
    } catch (_) {
      return 0;
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
          ).limit(200),
    );

    if (includeLegacy) {
      await mergeQuery(
        _firestore.collection("conversations").where(
              "userID1",
              isEqualTo: uid,
            ).limit(200),
      );
      await mergeQuery(
        _firestore.collection("conversations").where(
              "userID2",
              isEqualTo: uid,
            ).limit(200),
      );
    }

    return docsById.values.toList(growable: false);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserConversations(
      String uid) {
    return _firestore
        .collection("conversations")
        .where(
          Filter.or(
            Filter("participants", arrayContains: uid),
            Filter("userID1", isEqualTo: uid),
            Filter("userID2", isEqualTo: uid),
          ),
        )
        .limit(200)
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
