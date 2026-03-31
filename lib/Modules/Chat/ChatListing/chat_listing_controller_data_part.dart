part of 'chat_listing_controller.dart';

extension ChatListingControllerDataPart on ChatListingController {
  Future<void> _bootstrapCacheFirstList() async {
    await _restoreCachedList();
    if (_cacheLoaded) return;
    await getList(forceServer: false);
  }

  Future<void> _restoreCachedList() async {
    if (_cacheLoaded) return;
    final cached = await _loadCachedList();
    if (cached == null || cached.isEmpty) return;
    list.value = cached;
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _cacheLoaded = true;
  }

  Future<List<ChatListingModel>?> _loadCachedList() async {
    final key = _cacheKey;
    if (key.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await prefs.remove(key);
        return null;
      }
      final restored = decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatListingModel.fromJson)
          .toList();
      if (restored.isEmpty && decoded.isNotEmpty) {
        await prefs.remove(key);
      }
      return restored;
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } catch (_) {}
      return null;
    }
  }

  Future<void> _saveCachedList(List<ChatListingModel> items) async {
    final key = _cacheKey;
    if (key.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (items.isEmpty) {
        await prefs.remove(key);
        return;
      }
      final payload = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(key, payload);
    } catch (_) {}
  }

  Future<void> getList({bool forceServer = false, bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (!silent) waiting.value = true;
    try {
      final cacheOnly = _isOffline;
      final shouldHitServer = !cacheOnly && forceServer;

      final archiveOverrides = await _fetchArchiveOverrides(
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );
      final deletedOverrides = await _fetchDeletedOverrides(
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );
      List<ChatListingModel> conversations = <ChatListingModel>[];
      try {
        conversations = await _fetchConversations(
          preferCache: !shouldHitServer,
          cacheOnly: cacheOnly,
        );
      } catch (_) {}

      final mergedByUser = <String, ChatListingModel>{};
      for (final item in conversations) {
        final existing = mergedByUser[item.userID];
        final forcedArchiveValue = archiveOverrides[item.userID];
        final deletedUntil = deletedOverrides[item.userID];
        if (forcedArchiveValue == true &&
            !item.deleted.contains("__archived__")) {
          item.deleted = [...item.deleted, "__archived__"];
        } else if (forcedArchiveValue == false &&
            item.deleted.contains("__archived__")) {
          item.deleted =
              item.deleted.where((e) => e != "__archived__").toList();
        }
        final itemTs = int.tryParse(item.timeStamp) ?? 0;
        final itemIsDeleted = deletedUntil != null && itemTs <= deletedUntil;
        if (itemIsDeleted && !item.deleted.contains("__deleted__")) {
          item.deleted = [...item.deleted, "__deleted__"];
        } else if (!itemIsDeleted && item.deleted.contains("__deleted__")) {
          item.deleted = item.deleted.where((e) => e != "__deleted__").toList();
        }
        if (existing == null) {
          mergedByUser[item.userID] = item;
          continue;
        }

        final archivedEither = existing.deleted.contains("__archived__") ||
            item.deleted.contains("__archived__");
        final archivedForced = forcedArchiveValue == true;
        final unarchivedForced = forcedArchiveValue == false;
        final pinnedEither = existing.isPinned || item.isPinned;
        final mutedEither = existing.isMuted || item.isMuted;

        final currentTs = itemTs;
        final existingTs = int.tryParse(existing.timeStamp) ?? 0;
        final existingIsDeleted =
            deletedUntil != null && existingTs <= deletedUntil;
        final shouldReplace = currentTs >= existingTs;
        if (shouldReplace) {
          if (!item.hasAuthoritativePreview &&
              item.lastMessage.isEmpty &&
              existing.lastMessage.isNotEmpty) {
            item.lastMessage = existing.lastMessage;
          }
          if ((archivedEither || archivedForced) &&
              !unarchivedForced &&
              !item.deleted.contains("__archived__")) {
            item.deleted = [...item.deleted, "__archived__"];
          } else if (unarchivedForced &&
              item.deleted.contains("__archived__")) {
            item.deleted =
                item.deleted.where((e) => e != "__archived__").toList();
          }
          if (itemIsDeleted && !item.deleted.contains("__deleted__")) {
            item.deleted = [...item.deleted, "__deleted__"];
          } else if (!itemIsDeleted && item.deleted.contains("__deleted__")) {
            item.deleted =
                item.deleted.where((e) => e != "__deleted__").toList();
          }
          item.isPinned = pinnedEither;
          item.isMuted = mutedEither;
          mergedByUser[item.userID] = item;
        } else {
          if ((archivedEither || archivedForced) &&
              !unarchivedForced &&
              !existing.deleted.contains("__archived__")) {
            existing.deleted = [...existing.deleted, "__archived__"];
          } else if (unarchivedForced &&
              existing.deleted.contains("__archived__")) {
            existing.deleted =
                existing.deleted.where((e) => e != "__archived__").toList();
          }
          if (existingIsDeleted && !existing.deleted.contains("__deleted__")) {
            existing.deleted = [...existing.deleted, "__deleted__"];
          } else if (!existingIsDeleted &&
              existing.deleted.contains("__deleted__")) {
            existing.deleted =
                existing.deleted.where((e) => e != "__deleted__").toList();
          }
          existing.isPinned = pinnedEither;
          existing.isMuted = mutedEither;
          mergedByUser[item.userID] = existing;
        }
      }

      final tempList = mergedByUser.values.toList()
        ..sort((a, b) {
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          final aTs = int.tryParse(a.timeStamp) ?? 0;
          final bTs = int.tryParse(b.timeStamp) ?? 0;
          return bTs.compareTo(aTs);
        });

      list.value = tempList;
      if (search.text.trim().isEmpty) {
        _applyTabFilter();
      } else {
        _onSearchChanged();
      }
    } finally {
      _isRefreshing = false;
      if (!silent) waiting.value = false;
    }
    _saveCachedList(list.toList());
  }

  Future<Map<String, bool>> _fetchArchiveOverrides({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    return _conversationRepository.fetchArchiveOverrides(
      _uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }

  Future<Map<String, int>> _fetchDeletedOverrides({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    return _conversationRepository.fetchDeletedOverrides(
      _uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }

  Future<List<ChatListingModel>> _fetchConversations({
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final uid = _uid;
    final docs = await _conversationRepository.fetchUserConversations(
      uid,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      includeLegacy: true,
    );
    return _buildListingsFromConversationDocs(
      docs,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      existingByChatId: {
        for (final item in list)
          item.chatID: ChatListingModel.fromJson(item.toJson()),
      },
    );
  }

  Future<List<ChatListingModel>> _buildListingsFromConversationDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool preferCache,
    required bool cacheOnly,
    required Map<String, ChatListingModel> existingByChatId,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) return const <ChatListingModel>[];
    final prefs = await SharedPreferences.getInstance();
    final userCache = ensureUserProfileCacheService();
    final tempList = <ChatListingModel>[];

    for (final doc in docs) {
      final data = doc.data();
      final existing = existingByChatId[doc.id];
      final isArchived =
          _conversationRepository.participantBoolValue(data["archived"], uid);
      final isPinned =
          _conversationRepository.participantBoolValue(data["pinned"], uid);
      final isMuted =
          _conversationRepository.participantBoolValue(data["muted"], uid);
      final userID1 = (data["userID1"] ?? "").toString().trim();
      final userID2 = (data["userID2"] ?? "").toString().trim();
      final participants =
          _conversationRepository.normalizeConversationParticipants(
        chatId: doc.id,
        currentUid: uid,
        participants: data["participants"] is List
            ? List<String>.from(
                (data["participants"] as List).map((e) => e.toString().trim()),
              ).where((e) => e.isNotEmpty).toList()
            : <String>[],
        userId1: userID1,
        userId2: userID2,
      );

      String? otherUserId = participants.firstWhereOrNull((v) => v != uid);
      if ((otherUserId == null || otherUserId.isEmpty) &&
          userID1.isNotEmpty &&
          userID2.isNotEmpty) {
        if (userID1 == uid) otherUserId = userID2;
        if (userID2 == uid) otherUserId = userID1;
      }
      if (otherUserId == null || otherUserId.isEmpty) continue;

      Map<String, dynamic>? userData;
      if (existing != null && existing.userID == otherUserId) {
        final nameParts = existing.fullName
            .split(' ')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList(growable: false);
        userData = <String, dynamic>{
          'nickname': existing.nickname,
          'firstName': nameParts.isEmpty ? '' : nameParts.first,
          'lastName':
              nameParts.length <= 1 ? '' : nameParts.skip(1).join(' ').trim(),
          'avatarUrl': existing.avatarUrl,
        };
      }
      userData ??= await userCache.getProfile(
        otherUserId,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (userData == null) continue;

      final serverUnread =
          _conversationRepository.participantIntValue(data["unread"], uid);
      final hasPreviewOverride =
          _conversationRepository.participantMapContainsKey(
        data["previewText"],
        uid,
      );
      final previewText = hasPreviewOverride
          ? _conversationRepository.participantStringValue(
              data["previewText"],
              uid,
            )
          : (data["lastMessage"] ?? "").toString();
      final lastMessageAt = data["lastMessageAt"];
      int ts = 0;
      if (lastMessageAt is Timestamp) {
        ts = lastMessageAt.millisecondsSinceEpoch;
      } else {
        final fallbackTs = data["lastMessageAtMs"];
        ts = fallbackTs is int ? fallbackTs : int.tryParse("$fallbackTs") ?? 0;
      }
      if (hasPreviewOverride) {
        ts = _conversationRepository.participantIntValue(
          data["previewAt"],
          uid,
          defaultValue: ts,
        );
      }
      final lastSenderId = (data["lastSenderId"] ?? "").toString();
      final seenKey = "chat_last_opened_${uid}_${doc.id}";
      final seenTs = prefs.getInt(seenKey) ?? 0;
      final deletedCutoff =
          _conversationRepository.participantIntValue(data["deletedAt"], uid);
      final isDeleted = deletedCutoff > 0 && ts > 0 && ts <= deletedCutoff;
      final unreadCount = ChatUnreadPolicy.resolveUnreadCount(
        serverUnread: serverUnread,
        lastMessageAtMs: ts,
        locallySeenAtMs: seenTs,
        currentUid: uid,
        lastSenderId: lastSenderId,
        deletedCutoffMs: deletedCutoff,
      );

      tempList.add(ChatListingModel(
        chatID: doc.id,
        userID: otherUserId,
        timeStamp: ts.toString(),
        deleted: [
          if (isArchived) "__archived__",
          if (isDeleted) "__deleted__",
        ],
        nickname: (userData["nickname"] ??
                userData["username"] ??
                userData["displayName"] ??
                "")
            .toString(),
        fullName: "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}"
            .trim(),
        avatarUrl: (userData["avatarUrl"] ?? "").toString(),
        lastMessage: previewText,
        unreadCount: unreadCount,
        isConversation: true,
        isPinned: isPinned,
        isMuted: isMuted,
        hasAuthoritativePreview: hasPreviewOverride,
      ));
    }

    return tempList;
  }

  Future<void> _applyRealtimeConversationSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return;
    final existingByChatId = {
      for (final item in list)
        item.chatID: ChatListingModel.fromJson(item.toJson()),
    };
    final next = {
      for (final entry in existingByChatId.entries) entry.key: entry.value,
    };
    final updated = await _buildListingsFromConversationDocs(
      docs,
      preferCache: true,
      cacheOnly: _isOffline,
      existingByChatId: existingByChatId,
    );
    for (final item in updated) {
      next[item.chatID] = item;
    }
    final sorted = _sortChatListings(next.values.toList(growable: false));
    list.assignAll(sorted);
    if (search.text.trim().isEmpty) {
      _applyTabFilter();
    } else {
      _onSearchChanged();
    }
    _saveCachedList(sorted);
    _cacheLoaded = true;
  }

  List<ChatListingModel> _sortChatListings(List<ChatListingModel> items) {
    final sorted = [...items];
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

  void startConversationListener() {
    final uid = _uid;
    _syncTimer?.cancel();
    _conversationsSub?.cancel();
    if (uid.isEmpty) return;

    if (!_isOffline) {
      _conversationsSub = _conversationRepository
          .watchUserConversations(uid)
          .listen((snapshot) {
        _realtimeRefreshDebounce?.cancel();
        _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 350), () {
          unawaited(_applyRealtimeConversationSnapshot(snapshot.docs));
        });
      }, onError: (_) {});
      return;
    }

    _syncTimer = Timer.periodic(_syncInterval, (_) {
      getList(forceServer: false, silent: true);
    });
  }
}
