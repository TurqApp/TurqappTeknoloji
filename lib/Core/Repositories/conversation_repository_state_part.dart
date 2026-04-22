part of 'conversation_repository.dart';

Map<String, dynamic> _cloneConversationMap(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _cloneConversationValue(value)),
  );
}

dynamic _cloneConversationValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneConversationValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneConversationValue).toList(growable: false);
  }
  return value;
}

extension ConversationRepositoryStatePart on ConversationRepository {
  void _debugDeletePermissionDenied({
    required String stage,
    required FirebaseException error,
    required StackTrace errorStackTrace,
    required StackTrace invocationStackTrace,
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    if (error.code != 'permission-denied') return;
    final detailString = details.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    debugPrint(
      '[ChatDelete] stage=$stage status=permission_denied '
      '${detailString.isEmpty ? '' : '$detailString '}message=${error.message ?? ''}',
    );
    debugPrintStack(
      label: '[ChatDelete] stage=$stage invocation_stack',
      stackTrace: invocationStackTrace,
    );
    debugPrintStack(
      label: '[ChatDelete] stage=$stage error_stack',
      stackTrace: errorStackTrace,
    );
  }

  List<String> normalizeConversationParticipants({
    required String chatId,
    required String currentUid,
    required List<String> participants,
    required String userId1,
    required String userId2,
  }) {
    final cleaned = participants
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (cleaned.length == 2 && cleaned.contains(currentUid)) {
      cleaned.sort();
      return cleaned;
    }

    final inferred = <String>{};
    if (userId1.trim().isNotEmpty) inferred.add(userId1.trim());
    if (userId2.trim().isNotEmpty) inferred.add(userId2.trim());
    for (final part in chatId.split('_')) {
      final candidate = part.trim();
      if (candidate.isNotEmpty) inferred.add(candidate);
    }
    if (inferred.length != 2 || !inferred.contains(currentUid)) return cleaned;
    final normalized = inferred.toList()..sort();
    unawaited(
      _firestore.collection('conversations').doc(chatId).set({
        'participants': normalized,
        'userID1': normalized.first,
        'userID2': normalized.last,
      }, SetOptions(merge: true)),
    );
    return normalized;
  }

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

  String participantStringValue(
    dynamic raw,
    String uid, {
    String defaultValue = '',
  }) {
    return _sanitizeStringParticipantMap(
          raw,
          <String>[uid],
          defaultValue: defaultValue,
        )[uid] ??
        defaultValue;
  }

  bool participantMapContainsKey(dynamic raw, String uid) {
    if (raw is! Map) return false;
    if (raw.containsKey(uid)) return true;
    return raw.keys.any((key) => key.toString() == uid);
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
      map[otherUid] = participantBoolValue(
        archivedMap,
        currentUid,
        defaultValue: false,
      );
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
      final deletedAt = participantIntValue(
        deletedMap,
        currentUid,
        defaultValue: 0,
      );
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
    final invocationStackTrace = StackTrace.current;
    try {
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
    } on FirebaseException catch (error, stackTrace) {
      _debugDeletePermissionDenied(
        stage: 'set_archived_user_state',
        error: error,
        errorStackTrace: stackTrace,
        invocationStackTrace: invocationStackTrace,
        details: <String, Object?>{
          'chatId': chatId,
          'currentUid': currentUid,
          'otherUserId': otherUserId,
          'archived': archived,
        },
      );
      rethrow;
    }
    try {
      await _firestore.collection("conversations").doc(chatId).set({
        "archived.$currentUid": archived,
      }, SetOptions(merge: true));
    } on FirebaseException catch (error, stackTrace) {
      _debugDeletePermissionDenied(
        stage: 'set_archived_conversation_state',
        error: error,
        errorStackTrace: stackTrace,
        invocationStackTrace: invocationStackTrace,
        details: <String, Object?>{
          'chatId': chatId,
          'currentUid': currentUid,
          'archived': archived,
        },
      );
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
    final invocationStackTrace = StackTrace.current;
    try {
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
    } on FirebaseException catch (error, stackTrace) {
      _debugDeletePermissionDenied(
        stage: 'set_deleted_cutoff',
        error: error,
        errorStackTrace: stackTrace,
        invocationStackTrace: invocationStackTrace,
        details: <String, Object?>{
          'chatId': chatId,
          'currentUid': currentUid,
          'otherUserId': otherUserId,
          'deletedAt': deletedAt,
        },
      );
      rethrow;
    }
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
          return _cloneConversationMap(
            cached.data() ?? const <String, dynamic>{},
          );
        }
      } catch (_) {}
    }
    if (cacheOnly) return null;
    final doc = await ref.get();
    if (!doc.exists) return null;
    return _cloneConversationMap(
      doc.data() ?? const <String, dynamic>{},
    );
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
