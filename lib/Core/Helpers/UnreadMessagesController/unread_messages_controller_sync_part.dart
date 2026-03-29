part of 'unread_messages_controller_library.dart';

extension UnreadMessagesControllerSyncPart on UnreadMessagesController {
  String _conversationUnreadKey(String otherUid, String chatId) {
    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isNotEmpty) {
      return '__chat__:$normalizedChatId';
    }
    return otherUid.trim();
  }

  void startListeners({bool force = false}) {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    if (!force && _listenersStarted && _activeUid == uid) return;

    _cancelAllSubscriptions();
    _listenersStarted = true;
    _activeUid = uid;
    _readStateReady = false;
    totalUnreadCount.value = 0;
    unawaited(_startAfterReadStateHydrated(uid));
  }

  // Firestore read tetiklemeden, tek konuşmanın unread durumunu localde günceller.
  void updateConversationUnreadLocal({
    required String otherUid,
    required int unreadCount,
    String? chatId,
    int? seenAtMs,
  }) {
    final normalizedChatId = (chatId ?? "").trim();
    final normalizedOtherUid = otherUid.trim();
    final key = _conversationUnreadKey(normalizedOtherUid, normalizedChatId);
    if (key.isEmpty && normalizedOtherUid.isEmpty) return;
    if (unreadCount <= 0) {
      _conversationUnreadByUser.remove(key);
      if (normalizedOtherUid.isNotEmpty) {
        _conversationUnreadByUser.remove(normalizedOtherUid);
      }
      if (normalizedChatId.isNotEmpty) {
        final cutoff = seenAtMs ?? DateTime.now().millisecondsSinceEpoch;
        _localReadCutoffByChatId[normalizedChatId] = cutoff;
        _persistedReadCutoffByChatId[normalizedChatId] = cutoff;
        unawaited(_persistReadCutoff(normalizedChatId, cutoff));
      }
    } else {
      _conversationUnreadByUser[key] = unreadCount;
      if (normalizedOtherUid.isNotEmpty && key != normalizedOtherUid) {
        _conversationUnreadByUser.remove(normalizedOtherUid);
      }
      if (normalizedChatId.isNotEmpty) {
        _localReadCutoffByChatId.remove(normalizedChatId);
      }
    }
    _recomputeTotalUnread();
  }

  Future<void> refreshUnreadCount() async {
    await _syncUnread(forceServer: true);
  }

  Future<void> _syncUnread({required bool forceServer}) async {
    final uid = _currentUid;
    if (uid.isEmpty || _isSyncing) return;

    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly &&
        (forceServer ||
            _lastServerSyncAt == null ||
            DateTime.now().difference(_lastServerSyncAt!) > _serverSyncGap);
    _isSyncing = true;
    try {
      final docs = await _conversationRepository.fetchUserConversations(
        uid,
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
        includeLegacy: true,
      );
      _applyConversationDocs(docs, uid);
      if (shouldHitServer) {
        _lastServerSyncAt = DateTime.now();
      }
    } catch (_) {
      _recomputeTotalUnread();
    } finally {
      _isSyncing = false;
    }
  }

  void _applyConversationDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String uid,
  ) {
    _conversationUnreadByUser.clear();
    for (final doc in docs) {
      final data = doc.data();
      final unreadMap = Map<String, dynamic>.from(data["unread"] ?? {});
      final value = unreadMap[uid];
      final serverUnreadRaw =
          value is num ? value.toInt() : int.tryParse("$value") ?? 0;
      var unread = serverUnreadRaw;
      final lastSenderId = (data["lastSenderId"] ?? "").toString();

      int lastMessageAtMs = 0;
      final lastMessageAt = data["lastMessageAt"];
      if (lastMessageAt is Timestamp) {
        lastMessageAtMs = lastMessageAt.millisecondsSinceEpoch;
      } else {
        final fallback = data["lastMessageAtMs"];
        lastMessageAtMs =
            fallback is int ? fallback : int.tryParse("$fallback") ?? 0;
      }
      final effectiveReadCutoff = ChatUnreadPolicy.maxLocalReadCutoff([
        _localReadCutoffByChatId[doc.id] ?? 0,
        _persistedReadCutoffByChatId[doc.id] ?? 0,
      ]);
      final deletedCutoff =
          _conversationRepository.participantIntValue(data["deletedAt"], uid);
      unread = ChatUnreadPolicy.resolveUnreadCount(
        serverUnread: serverUnreadRaw,
        lastMessageAtMs: lastMessageAtMs,
        locallySeenAtMs: effectiveReadCutoff,
        currentUid: uid,
        lastSenderId: lastSenderId,
        deletedCutoffMs: deletedCutoff,
      );
      if (unread <= 0) continue;
      final participants = List<String>.from(data["participants"] ?? []);
      final otherUid = participants.firstWhere(
        (v) => v != uid,
        orElse: () => doc.id,
      );
      _conversationUnreadByUser[_conversationUnreadKey(otherUid, doc.id)] =
          unread;
    }
    _recomputeTotalUnread();
  }

  Future<void> _startAfterReadStateHydrated(String uid) async {
    await _hydratePersistedReadState(uid);
    if (!_listenersStarted || _activeUid != uid) return;
    _readStateReady = true;
    _conversationsSub =
        _conversationRepository.watchUserConversations(uid).listen((snapshot) {
      _applyConversationDocs(snapshot.docs, uid);
    }, onError: (_) {});
    if (_isOffline) {
      unawaited(_syncUnread(forceServer: false));
      _syncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        unawaited(_syncUnread(forceServer: false));
      });
    }
  }

  Future<void> _hydratePersistedReadState(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = "chat_last_opened_${uid}_";
      final next = <String, int>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(prefix)) continue;
        final chatId = key.substring(prefix.length).trim();
        if (chatId.isEmpty) continue;
        final ms = prefs.getInt(key) ?? 0;
        if (ms <= 0) continue;
        next[chatId] = ms;
      }
      _persistedReadCutoffByChatId
        ..clear()
        ..addAll(next);
      if (_activeUid == uid && _listenersStarted) {
        unawaited(_syncUnread(forceServer: false));
      }
    } catch (_) {}
  }

  Future<void> _persistReadCutoff(String chatId, int cutoffMs) async {
    final uid = _currentUid;
    if (uid.isEmpty || chatId.trim().isEmpty || cutoffMs <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("chat_last_opened_${uid}_$chatId", cutoffMs);
    } catch (_) {}
  }

  void _cancelAllSubscriptions() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _conversationsSub?.cancel();
    _conversationsSub = null;
    _conversationUnreadByUser.clear();
    _localReadCutoffByChatId.clear();
    _persistedReadCutoffByChatId.clear();
    _readStateReady = false;
    totalUnreadCount.value = 0;
    _listenersStarted = false;
    _activeUid = null;
  }
}
