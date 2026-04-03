part of 'unread_messages_controller_library.dart';

extension UnreadMessagesControllerSyncPart on UnreadMessagesController {
  static const int _liveConversationWindowSize = 30;

  String _conversationUnreadKey(String otherUid, String chatId) {
    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isNotEmpty) {
      return '__chat__:$normalizedChatId';
    }
    return otherUid.trim();
  }

  String _chatListingCacheKey(String uid) =>
      uid.trim().isEmpty ? '' : 'chat_listing_cache_${uid.trim()}';

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

  void stopListeners() {
    _lastServerSyncAt = null;
    _isSyncing = false;
    _cancelAllSubscriptions();
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

  void replaceUnreadFromChatListings(Iterable<ChatListingModel> items) {
    final next = <String, ChatListingModel>{};
    for (final item in items) {
      final chatId = item.chatID.trim();
      if (chatId.isEmpty) continue;
      next[chatId] = ChatListingModel.fromJson(item.toJson());
    }
    _cachedListingsByChatId
      ..clear()
      ..addAll(next);
    _rebuildUnreadFromCachedListings();
    _refreshLiveWindowListeners();
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
    for (final doc in docs) {
      _mergeConversationDataIntoCachedListing(
        chatId: doc.id,
        data: doc.data(),
        uid: uid,
      );
    }
    _rebuildUnreadFromCachedListings();
    _refreshLiveWindowListeners();
  }

  Future<void> _startAfterReadStateHydrated(String uid) async {
    await _hydratePersistedReadState(uid);
    if (!_listenersStarted || _activeUid != uid) return;
    _readStateReady = true;
    final restored = await _hydrateUnreadFromListingCache(uid);
    if (!_listenersStarted || _activeUid != uid) return;
    if (!restored) {
      await _seedUnreadFromFirestoreCache();
      if (!_listenersStarted || _activeUid != uid) return;
    } else {
      _refreshLiveWindowListeners();
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
      if (_activeUid == uid && _listenersStarted && _readStateReady) {
        _rebuildUnreadFromCachedListings();
      }
    } catch (_) {}
  }

  Future<bool> _hydrateUnreadFromListingCache(String uid) async {
    final key = _chatListingCacheKey(uid);
    if (key.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await prefs.remove(key);
        return false;
      }
      final restored = decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatListingModel.fromJson)
          .toList(growable: false);
      if (restored.isEmpty) {
        return false;
      }
      replaceUnreadFromChatListings(restored);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _seedUnreadFromFirestoreCache() async {
    final uid = _currentUid;
    if (uid.isEmpty || _isSyncing) return;
    _isSyncing = true;
    try {
      final docs = await _conversationRepository.fetchUserConversations(
        uid,
        preferCache: true,
        cacheOnly: true,
        includeLegacy: true,
      );
      _applyConversationDocs(docs, uid);
    } catch (_) {
      _recomputeTotalUnread();
    } finally {
      _isSyncing = false;
    }
  }

  ChatListingModel? _mergeConversationDataIntoCachedListing({
    required String chatId,
    required Map<String, dynamic> data,
    required String uid,
  }) {
    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isEmpty) return null;

    final userID1 = (data["userID1"] ?? "").toString().trim();
    final userID2 = (data["userID2"] ?? "").toString().trim();
    final participants =
        _conversationRepository.normalizeConversationParticipants(
      chatId: normalizedChatId,
      currentUid: uid,
      participants: data["participants"] is List
          ? List<String>.from(
              (data["participants"] as List).map((e) => e.toString().trim()),
            ).where((e) => e.isNotEmpty).toList()
          : <String>[],
      userId1: userID1,
      userId2: userID2,
    );

    var otherUid = participants.firstWhere(
      (value) => value != uid,
      orElse: () => '',
    );
    if (otherUid.isEmpty && userID1.isNotEmpty && userID2.isNotEmpty) {
      if (userID1 == uid) otherUid = userID2;
      if (userID2 == uid) otherUid = userID1;
    }
    if (otherUid.isEmpty) return null;

    final serverUnreadRaw =
        _conversationRepository.participantIntValue(data["unread"], uid);
    final lastSenderId = (data["lastSenderId"] ?? "").toString().trim();
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
      _localReadCutoffByChatId[normalizedChatId] ?? 0,
      _persistedReadCutoffByChatId[normalizedChatId] ?? 0,
    ]);
    final deletedCutoff =
        _conversationRepository.participantIntValue(data["deletedAt"], uid);
    final unread = ChatUnreadPolicy.resolveUnreadCount(
      serverUnread: serverUnreadRaw,
      lastMessageAtMs: lastMessageAtMs,
      locallySeenAtMs: effectiveReadCutoff,
      currentUid: uid,
      lastSenderId: lastSenderId,
      deletedCutoffMs: deletedCutoff,
    );
    final isArchived =
        _conversationRepository.participantBoolValue(data["archived"], uid);
    final isPinned =
        _conversationRepository.participantBoolValue(data["pinned"], uid);
    final isMuted =
        _conversationRepository.participantBoolValue(data["muted"], uid);
    final isDeleted = deletedCutoff > 0 &&
        lastMessageAtMs > 0 &&
        lastMessageAtMs <= deletedCutoff;

    final existing = _cachedListingsByChatId[normalizedChatId];
    final updated = existing == null
        ? ChatListingModel(
            chatID: normalizedChatId,
            userID: otherUid,
            timeStamp: '$lastMessageAtMs',
            deleted: const <String>[],
            nickname: '',
            fullName: '',
            avatarUrl: '',
            unreadCount: unread,
            isConversation: true,
            isPinned: isPinned,
            isMuted: isMuted,
          )
        : ChatListingModel.fromJson(existing.toJson());
    updated.userID = otherUid;
    updated.timeStamp = '$lastMessageAtMs';
    updated.unreadCount = unread;
    updated.isPinned = isPinned;
    updated.isMuted = isMuted;
    final nextDeletedFlags = updated.deleted
        .where((value) => value != "__archived__" && value != "__deleted__")
        .toList();
    if (isArchived) {
      nextDeletedFlags.add("__archived__");
    }
    if (isDeleted) {
      nextDeletedFlags.add("__deleted__");
    }
    updated.deleted = nextDeletedFlags;
    _cachedListingsByChatId[normalizedChatId] = updated;
    return updated;
  }

  void _rebuildUnreadFromCachedListings() {
    final nextUnread = <String, int>{};
    for (final item in _cachedListingsByChatId.values) {
      if (item.deleted.contains("__deleted__") || item.unreadCount <= 0) {
        continue;
      }
      nextUnread[_conversationUnreadKey(item.userID, item.chatID)] =
          item.unreadCount;
    }
    _conversationUnreadByUser
      ..clear()
      ..addAll(nextUnread);
    _recomputeTotalUnread();
  }

  List<ChatListingModel> _sortedCachedListings() {
    final sorted = _cachedListingsByChatId.values
        .map((item) => ChatListingModel.fromJson(item.toJson()))
        .toList(growable: false);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final aTs = int.tryParse(a.timeStamp) ?? 0;
      final bTs = int.tryParse(b.timeStamp) ?? 0;
      return bTs.compareTo(aTs);
    });
    return sorted;
  }

  void _refreshLiveWindowListeners() {
    if (_isOffline) {
      _cancelLiveWindowListeners();
      return;
    }
    final desiredChatIds = _sortedCachedListings()
        .take(_liveConversationWindowSize)
        .map((item) => item.chatID.trim())
        .where((chatId) => chatId.isNotEmpty)
        .toSet();
    final currentChatIds = _liveConversationSubs.keys.toSet();

    for (final chatId in currentChatIds.difference(desiredChatIds)) {
      unawaited(_liveConversationSubs.remove(chatId)?.cancel());
    }

    for (final chatId in desiredChatIds.difference(currentChatIds)) {
      _liveConversationSubs[chatId] =
          _conversationRepository.watchConversation(chatId).listen((snapshot) {
        unawaited(_applyRealtimeConversationDocument(snapshot));
      }, onError: (_) {});
    }
  }

  Future<void> _applyRealtimeConversationDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final uid = _currentUid;
    if (uid.isEmpty || !snapshot.exists) return;
    final data = snapshot.data();
    if (data == null || data.isEmpty) return;
    final updated = _mergeConversationDataIntoCachedListing(
      chatId: snapshot.id,
      data: data,
      uid: uid,
    );
    if (updated == null) return;
    _rebuildUnreadFromCachedListings();
    _refreshLiveWindowListeners();
  }

  void _cancelLiveWindowListeners() {
    final subscriptions = _liveConversationSubs.values.toList(growable: false);
    _liveConversationSubs.clear();
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
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
    _cancelLiveWindowListeners();
    _conversationUnreadByUser.clear();
    _cachedListingsByChatId.clear();
    _localReadCutoffByChatId.clear();
    _persistedReadCutoffByChatId.clear();
    _readStateReady = false;
    totalUnreadCount.value = 0;
    _listenersStarted = false;
    _activeUid = null;
  }
}
