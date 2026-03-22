part of 'conversation_repository.dart';

extension ConversationRepositoryStatePart on ConversationRepository {
  bool participantBoolValue(
    dynamic raw,
    String uid, {
    bool defaultValue = false,
  }) {
    return _sanitizeBoolParticipantMap(
          raw,
          <String>[uid],
          defaultValue: defaultValue,
        )[uid] ??
        defaultValue;
  }

  int participantIntValue(
    dynamic raw,
    String uid, {
    int defaultValue = 0,
    bool nonNegative = true,
  }) {
    return _sanitizeIntParticipantMap(
          raw,
          <String>[uid],
          defaultValue: defaultValue,
          nonNegative: nonNegative,
        )[uid] ??
        defaultValue;
  }

  Map<String, bool> deriveArchiveOverridesFromConversationDocs(
    String currentUid,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, bool>{};
    for (final doc in docs) {
      final data = doc.data();
      final otherUid = _resolveOtherUidFromConversationDoc(currentUid, doc);
      if (otherUid.isEmpty) continue;
      final archivedMap = data["archived"];
      if (archivedMap is! Map) continue;
      final raw = archivedMap[currentUid];
      if (raw is bool) {
        map[otherUid] = raw;
      } else if (raw is num) {
        map[otherUid] = raw != 0;
      }
    }
    return map;
  }

  Map<String, int> deriveDeletedOverridesFromConversationDocs(
    String currentUid,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, int>{};
    for (final doc in docs) {
      final data = doc.data();
      final otherUid = _resolveOtherUidFromConversationDoc(currentUid, doc);
      if (otherUid.isEmpty) continue;
      final deletedMap = data["deletedAt"];
      if (deletedMap is! Map) continue;
      final raw = deletedMap[currentUid];
      final deletedAt = raw is int
          ? raw
          : raw is num
              ? raw.toInt()
              : int.tryParse("$raw") ?? 0;
      if (deletedAt > 0) {
        map[otherUid] = deletedAt;
      }
    }
    return map;
  }

  Future<void> setArchived({
    required String currentUid,
    required String otherUserId,
    required String chatId,
    required bool archived,
  }) async {
    await _firestore
        .collection("users")
        .doc(currentUid)
        .collection("chatArchives")
        .doc(otherUserId)
        .set({
      "userID": otherUserId,
      "chatID": chatId,
      "archived": archived,
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    try {
      await _firestore.collection("conversations").doc(chatId).set({
        "archived.$currentUid": archived,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> setUnreadCount({
    required String chatId,
    required String currentUid,
    required int unreadCount,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "unread.$currentUid": unreadCount < 0 ? 0 : unreadCount,
    }, SetOptions(merge: true));
  }

  Future<void> setPinned({
    required String chatId,
    required String currentUid,
    required bool pinned,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "pinned.$currentUid": pinned,
    }, SetOptions(merge: true));
  }

  Future<void> setMuted({
    required String chatId,
    required String currentUid,
    required bool muted,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "muted.$currentUid": muted,
    }, SetOptions(merge: true));
  }

  Future<void> setDeletedCutoff({
    required String currentUid,
    required String otherUserId,
    required String chatId,
    required int deletedAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationRef = _firestore.collection("conversations").doc(chatId);
    await _firestore
        .collection("users")
        .doc(currentUid)
        .collection("chatDeletions")
        .doc(otherUserId)
        .set({
      "userID": otherUserId,
      "chatID": chatId,
      "deletedAt": deletedAt,
      "updatedDate": now,
    }, SetOptions(merge: true));

    await _firestore
        .collection("users")
        .doc(currentUid)
        .collection("chatArchives")
        .doc(otherUserId)
        .set({
      "userID": otherUserId,
      "chatID": chatId,
      "archived": false,
      "updatedDate": now,
    }, SetOptions(merge: true));

    await conversationRef.set({
      "deletedAt.$currentUid": deletedAt,
      "archived.$currentUid": false,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getConversation(
    String chatId, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (chatId.trim().isEmpty) return null;
    final ref = _firestore.collection("conversations").doc(chatId.trim());
    if (preferCache) {
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        if (cached.exists) {
          return Map<String, dynamic>.from(
            cached.data() ?? const <String, dynamic>{},
          );
        }
      } catch (_) {}
    }
    if (cacheOnly) return null;
    final doc = await ref.get();
    if (!doc.exists) return null;
    return Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
  }

  Future<void> setMarketContext({
    required String chatId,
    required MarketItemModel item,
  }) async {
    if (chatId.trim().isEmpty || item.id.trim().isEmpty) return;
    await _firestore.collection('conversations').doc(chatId.trim()).set({
      'marketContext': {
        'itemId': item.id,
        'title': item.title,
        'coverImageUrl': item.coverImageUrl,
        'sellerId': item.userId,
      },
    }, SetOptions(merge: true));
  }

  Future<void> upsertConversationEnvelope({
    required String chatId,
    required String currentUid,
    required String otherUid,
    required String lastMessage,
    required int nowMs,
  }) async {
    final existing = await getConversation(
      chatId,
      preferCache: true,
      cacheOnly: false,
    );
    final envelope = _buildConversationEnvelope(
      existing: existing,
      currentUid: currentUid,
      otherUid: otherUid,
      lastMessage: lastMessage,
      nowMs: nowMs,
    );
    await _firestore
        .collection("conversations")
        .doc(chatId)
        .set(envelope, SetOptions(merge: true));
  }

  Future<void> setTypingTimestamp({
    required String chatId,
    required String currentUid,
    required int timestampMs,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "typing.$currentUid": timestampMs < 0 ? 0 : timestampMs,
    }, SetOptions(merge: true));
  }

  Future<void> setChatBackgroundIndex({
    required String chatId,
    required String currentUid,
    required int index,
  }) async {
    await _firestore.collection("conversations").doc(chatId).set({
      "chatBg.$currentUid": index.clamp(0, 5),
    }, SetOptions(merge: true));
  }

  Future<void> ensureConversationForPostShare({
    required String chatId,
    required String currentUid,
    required String otherUid,
    required int nowMs,
  }) async {
    await upsertConversationEnvelope(
      chatId: chatId,
      currentUid: currentUid,
      otherUid: otherUid,
      lastMessage: kConversationPostMessageMarker,
      nowMs: nowMs,
    );
  }
}
