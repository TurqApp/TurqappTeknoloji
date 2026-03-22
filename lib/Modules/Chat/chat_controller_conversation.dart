part of 'chat_controller.dart';

extension _ChatControllerConversationX on ChatController {
  Future<void> _clearConversationUnread() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      await _conversationRepository.setUnreadCount(
        chatId: chatID,
        currentUid: uid,
        unreadCount: 0,
      );
    } catch (_) {}
  }

  void _syncUnreadIndicatorsLocal() {
    UnreadMessagesController.maybeFind()?.updateConversationUnreadLocal(
      otherUid: userID,
      unreadCount: 0,
      chatId: chatID,
      seenAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    InAppNotificationsController.maybeFind()
        ?.markChatNotificationsReadLocal(chatId: chatID);
  }

  Future<void> _markConversationOpenedNow() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      "chat_last_opened_${uid}_$chatID",
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _markConversationOpenedAt(int timestampMs) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = "chat_last_opened_${uid}_$chatID";
    final old = prefs.getInt(key) ?? 0;
    if (timestampMs > old) {
      await prefs.setInt(key, timestampMs);
    }
  }

  void getUserData() async {
    try {
      final data = (await UserProfileCacheService.ensure().getProfile(
            userID,
            preferCache: true,
            cacheOnly: _isOffline,
          )) ??
          <String, dynamic>{};

      nickname.value =
          (data["nickname"] ?? data["username"] ?? data["displayName"] ?? "")
              .toString();
      avatarUrl.value = (data["avatarUrl"] ?? "").toString();
      token.value = (data["token"] ?? "").toString();

      final firstName = (data["firstName"] ?? "").toString().trim();
      final lastName = (data["lastName"] ?? "").toString().trim();
      final full = "$firstName $lastName".trim();
      fullName.value = full.isNotEmpty
          ? full
          : (data["fullName"] ?? nickname.value).toString();
      bio.value = (data["bio"] ?? "").toString();

      followersCount.value = _asInt(
          data["followersCount"] ?? data["takipci"] ?? data["followerCount"]);
      followingCount.value = _asInt(
          data["followingCount"] ?? data["takip"] ?? data["followCount"]);
      postCount.value =
          _asInt(data["postCount"] ?? data["gonderi"] ?? data["postsCount"]);
    } catch (_) {}
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is List) return value.length;
    return 0;
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTypingChanged() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final text = textEditingController.text;
    if (text.isNotEmpty) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final shouldSendHeartbeat = !_typingActive ||
          (nowMs - _lastTypingHeartbeatMs) >=
              ChatController._typingHeartbeatIntervalMs;
      if (shouldSendHeartbeat) {
        try {
          _conversationRepository.setTypingTimestamp(
            chatId: chatID,
            currentUid: uid,
            timestampMs: nowMs,
          );
          _typingActive = true;
          _lastTypingHeartbeatMs = nowMs;
        } catch (_) {}
      }
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), _clearTyping);
    } else {
      _clearTyping();
    }
  }

  void _clearTyping() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    if (!_typingActive) return;
    try {
      _conversationRepository.setTypingTimestamp(
        chatId: chatID,
        currentUid: uid,
        timestampMs: 0,
      );
      _typingActive = false;
      _lastTypingHeartbeatMs = 0;
    } catch (_) {}
  }

  void _listenTypingState() {
    _typingStream = _conversationRepository.watchConversation(chatID).listen((
      doc,
    ) {
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      _recipientMuted =
          _conversationRepository.participantBoolValue(data["muted"], userID);
      final otherTs = _conversationRepository.participantIntValue(
        data["typing"],
        userID,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      isOtherTyping.value = otherTs > 0 && (now - otherTs) < 3000;

      int lastMessageAtMs = 0;
      final lmAt = data["lastMessageAt"];
      if (lmAt is Timestamp) {
        lastMessageAtMs = lmAt.millisecondsSinceEpoch;
      } else {
        final fallback = data["lastMessageAtMs"];
        lastMessageAtMs =
            fallback is int ? fallback : int.tryParse("$fallback") ?? 0;
      }
      if (lastMessageAtMs > 0) {
        unawaited(_markConversationOpenedAt(lastMessageAtMs));
      }
    });
  }

  Future<void> getData() async {
    _messageSyncTimer?.cancel();
    _messagesSubscription?.cancel();
    _realtimeHeadSignature = '';

    final hasLocalWindow = await _loadLocalConversationWindow();
    await _loadInitialMessages(forceServer: !hasLocalWindow);
    _listenRealtimeMessages(cacheOnly: hasLocalWindow);
    if (_isOffline) {
      _messageSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _syncMessages(forceServer: false);
      });
    }
  }

  Future<void> loadChatBackgroundPreference() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final data = await _conversationRepository.getConversation(
            chatID,
            preferCache: true,
            cacheOnly: false,
          ) ??
          const <String, dynamic>{};
      final legacyRaw = data["chatBgIndex"];
      final legacyIdx = legacyRaw is int
          ? legacyRaw
          : legacyRaw is num
              ? legacyRaw.toInt()
              : int.tryParse("$legacyRaw") ?? 0;
      var idx = _conversationRepository.participantIntValue(
        data["chatBg"],
        uid,
        defaultValue: legacyIdx,
      );
      _recipientMuted =
          _conversationRepository.participantBoolValue(data["muted"], userID);
      if (idx < 0) idx = 0;
      if (idx > 5) idx = 5;
      chatBgPaletteIndex.value = idx;
    } catch (_) {}
  }

  Future<void> setChatBackgroundPreference(int index) async {
    if (index < 0 || index > 5) return;
    chatBgPaletteIndex.value = index;
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      await _conversationRepository.setChatBackgroundIndex(
        chatId: chatID,
        currentUid: uid,
        index: index,
      );
    } catch (_) {}
  }

  void _listenRealtimeMessages({bool cacheOnly = false}) {
    _messagesSubscription = _conversationRepository
        .watchConversationMessagesHead(
      chatID,
      limit: ChatController._syncHeadSize,
      cacheOnly: cacheOnly,
    )
        .listen((snapshot) {
      if (!_isOffline && !cacheOnly) {
        _messageSyncTimer?.cancel();
        _messageSyncTimer = null;
      } else if (!_isOffline && cacheOnly && _messageSyncTimer == null) {
        _messageSyncTimer = Timer.periodic(_serverSyncGap, (_) {
          _syncMessages(forceServer: true);
        });
      }
      if (cacheOnly) {
        _applyConversationSnapshot(snapshot.docs, replace: false);
        _refreshMergedMessages();
        return;
      }
      if (snapshot.docs.isEmpty) return;
      final previousHeadSignature = _realtimeHeadSignature;
      final nextHeadSignature = _buildHeadSignature(snapshot.docs);
      _realtimeHeadSignature = nextHeadSignature;
      final latestRemoteTs = _extractCreatedDateMs(snapshot.docs.first.data());
      final shouldSync = ChatRealtimeSyncPolicy.shouldTriggerSync(
        previousHeadSignature: previousHeadSignature,
        nextHeadSignature: nextHeadSignature,
        latestLoadedTimestampMs: _latestLoadedTimestampMs(),
        latestRemoteTimestampMs: latestRemoteTs,
      );
      if (shouldSync) {
        unawaited(_syncMessages(forceServer: true));
      }
    }, onError: (_) {
      if (_messageSyncTimer != null) return;
      _messageSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _syncMessages(forceServer: true);
      });
    });
  }

  Future<void> _loadInitialMessages({required bool forceServer}) async {
    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly && forceServer;
    try {
      final conversationSnapshot =
          await _conversationRepository.fetchLatestMessages(
        chatID,
        limit: ChatController._initialPageSize,
        preferCache: !shouldHitServer,
        cacheOnly: cacheOnly,
      );

      _applyConversationSnapshot(conversationSnapshot.docs, replace: true);
      _conversationOldestCursor = conversationSnapshot.docs.isNotEmpty
          ? conversationSnapshot.docs.last
          : _conversationOldestCursor;

      _conversationHasMore =
          conversationSnapshot.docs.length >= ChatController._initialPageSize;
      _updateHasMoreOlder();
      _refreshMergedMessages();
      _lastServerSyncAt = DateTime.now();
    } catch (_) {}
  }

  Future<void> _syncMessages({required bool forceServer}) async {
    if (_isMessageSyncing) return;
    final cacheOnly = _isOffline;
    final shouldHitServer = !cacheOnly &&
        (forceServer ||
            _lastServerSyncAt == null ||
            DateTime.now().difference(_lastServerSyncAt!) > _serverSyncGap);
    _isMessageSyncing = true;
    try {
      final latestLoadedTs = _latestLoadedTimestampMs();
      final conversationSnapshot = latestLoadedTs > 0
          ? await _conversationRepository.fetchMessagesAfter(
              chatID,
              createdAfterMs: latestLoadedTs,
              limit: ChatController._syncHeadSize,
              preferCache: !shouldHitServer,
              cacheOnly: cacheOnly,
            )
          : await _conversationRepository.fetchLatestMessages(
              chatID,
              limit: ChatController._syncHeadSize,
              preferCache: !shouldHitServer,
              cacheOnly: cacheOnly,
            );

      _applyConversationSnapshot(conversationSnapshot.docs, replace: false);
      _refreshMergedMessages();

      if (shouldHitServer) {
        _lastServerSyncAt = DateTime.now();
      }
    } catch (_) {
    } finally {
      _isMessageSyncing = false;
    }
  }

  Future<void> loadOlderMessages() async {
    if (_isLoadingOlder) return;
    if (!_conversationHasMore) return;
    _isLoadingOlder = true;
    isLoadingOlder.value = true;
    try {
      final cacheOnly = _isOffline;
      if (_conversationHasMore && _conversationOldestCursor != null) {
        final convSnapshot = await _conversationRepository.fetchOlderMessages(
          chatID,
          startAfter: _conversationOldestCursor!,
          limit: ChatController._olderPageSize,
          preferCache: true,
          cacheOnly: cacheOnly,
        );
        _applyConversationSnapshot(convSnapshot.docs, replace: false);
        if (convSnapshot.docs.isNotEmpty) {
          _conversationOldestCursor = convSnapshot.docs.last;
        }
        _conversationHasMore =
            convSnapshot.docs.length >= ChatController._olderPageSize;
      }

      _updateHasMoreOlder();
      _refreshMergedMessages();
    } catch (_) {
    } finally {
      _isLoadingOlder = false;
      isLoadingOlder.value = false;
    }
  }

  Future<void> jumpToMessageByRawId(String rawId) async {
    if (rawId.trim().isEmpty) return;

    int index = messages.indexWhere((m) => m.rawDocID == rawId);
    var attempts = 0;
    while (index < 0 && attempts < 4 && hasMoreOlder.value) {
      await loadOlderMessages();
      index = messages.indexWhere((m) => m.rawDocID == rawId);
      attempts++;
    }

    if (index < 0) {
      AppSnackbar('common.info'.tr, 'chat.reply_target_missing'.tr);
      return;
    }

    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final target =
        (index * 120.0).clamp(0.0, position.maxScrollExtent).toDouble();
    await scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  void _updateHasMoreOlder() {
    hasMoreOlder.value = _conversationHasMore;
  }

  int _latestLoadedTimestampMs() {
    var latest = 0;
    for (final m in _conversationMessages.values) {
      final ts = m.timeStamp.toInt();
      if (ts > latest) latest = ts;
    }
    return latest;
  }

  int _extractCreatedDateMs(Map<String, dynamic> data) {
    final raw = data["createdDate"];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return int.tryParse("$raw") ?? 0;
  }

  int _extractUpdatedDateMs(Map<String, dynamic> data) {
    final raw = data["updatedDate"];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return int.tryParse("$raw") ?? 0;
  }

  String _buildHeadSignature(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return ChatRealtimeSyncPolicy.buildHeadSignature(
      docs.map((doc) {
        final data = doc.data();
        final reactions = data['reactions'];
        final seenBy = data['seenBy'];
        final likes = data['likes'];
        final deletedFor = data['deletedFor'];
        var reactionSelectionCount = 0;
        if (reactions is Map) {
          for (final value in reactions.values) {
            if (value is List) {
              reactionSelectionCount += value.length;
            }
          }
        }
        return ChatRealtimeHeadEntry(
          id: doc.id,
          createdDateMs: _extractCreatedDateMs(data),
          updatedDateMs: _extractUpdatedDateMs(data),
          status: (data['status'] ?? '').toString(),
          isEdited: data['isEdited'] == true,
          isUnsent: data['unsent'] == true,
          seenByCount: seenBy is List ? seenBy.length : 0,
          reactionBucketCount: reactions is Map ? reactions.length : 0,
          reactionSelectionCount: reactionSelectionCount,
          likeCount: likes is List ? likes.length : 0,
          deletedForCount: deletedFor is List ? deletedFor.length : 0,
        );
      }),
    );
  }
}
