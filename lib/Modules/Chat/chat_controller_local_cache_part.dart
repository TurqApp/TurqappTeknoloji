part of 'chat_controller.dart';

extension ChatControllerLocalCachePart on ChatController {
  Set<String> _expandLocalDeletedIdVariants(Iterable<String> ids) {
    final out = <String>{};
    for (final raw in ids) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      out.add(trimmed);
      final normalized = trimmed.replaceFirst(RegExp(r'^conv_'), '');
      if (normalized.isNotEmpty) {
        out.add(normalized);
        out.add('conv_$normalized');
      }
    }
    return out;
  }

  String get _localChatWindowKey {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return "chat_window_cache_guest_$chatID";
    return "chat_window_cache_${uid}_$chatID";
  }

  String get _localDeletedMessagesKey {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return "chat_deleted_messages_guest_$chatID";
    return "chat_deleted_messages_${uid}_$chatID";
  }

  Future<void> _loadLocalDeletedMessages() async {
    try {
      final preferences = ensureLocalPreferenceRepository();
      final ids = _expandLocalDeletedIdVariants(
        await preferences.getStringList(_localDeletedMessagesKey) ??
            const <String>[],
      );
      _localDeletedMessageIds
        ..clear()
        ..addAll(ids);
    } catch (_) {}
  }

  Future<void> _rememberLocalDeletedMessages(
      Iterable<String> messageIds) async {
    final ids = _expandLocalDeletedIdVariants(messageIds).toList();
    if (ids.isEmpty) return;
    _localDeletedMessageIds.addAll(ids);
    debugPrint(
      '[ChatDelete] stage=local_deleted_cache_buffered '
      'chatId=$chatID added=${ids.length} total=${_localDeletedMessageIds.length}',
    );
    try {
      final preferences = ensureLocalPreferenceRepository();
      final capped = _localDeletedMessageIds.toList(growable: false);
      final start = capped.length > 1000 ? capped.length - 1000 : 0;
      await preferences.setStringList(
        _localDeletedMessagesKey,
        capped.sublist(start),
      );
      debugPrint(
        '[ChatDelete] stage=local_deleted_cache_persisted '
        'chatId=$chatID persisted=${capped.length - start}',
      );
    } catch (_) {}
  }

  bool _isLocallyDeletedMessageId(String anyId) {
    final variants = _expandLocalDeletedIdVariants(<String>[anyId]);
    if (variants.isEmpty) return false;
    for (final variant in variants) {
      if (_localDeletedMessageIds.contains(variant)) {
        return true;
      }
    }
    return false;
  }

  bool _isLocallyDeletedMessageModel(MessageModel message) {
    final variants = _expandLocalDeletedIdVariants(
      <String>[message.rawDocID, message.docID],
    );
    if (variants.isEmpty) return false;
    for (final variant in variants) {
      if (_localDeletedMessageIds.contains(variant)) {
        return true;
      }
    }
    return false;
  }

  bool _isConversationMessageHiddenLocally(MessageModel message) {
    if (_isLocallyDeletedMessageModel(message)) return true;
    final ts = message.timeStamp.toInt();
    return _deletedConversationCutoffMs > 0 &&
        ts > 0 &&
        ts <= _deletedConversationCutoffMs;
  }

  Future<bool> _loadLocalConversationWindow() async {
    await _loadLocalDeletedMessages();
    final preferences = ensureLocalPreferenceRepository();
    final cacheKey = _localChatWindowKey;
    try {
      final raw = await preferences.getString(cacheKey);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await preferences.remove(cacheKey);
        return false;
      }

      final restored = <MessageModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final m = _deserializeLocalMessage(Map<String, dynamic>.from(item));
        if (m != null && _isConversationMessageHiddenLocally(m)) continue;
        if (m != null) restored.add(m);
      }
      if (restored.isEmpty) {
        await preferences.remove(cacheKey);
        return false;
      }
      restored.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      _conversationMessages
        ..clear()
        ..addEntries(
          restored.map((message) => MapEntry(message.docID, message)),
        );
      messages.value = restored;
      return true;
    } catch (_) {
      await preferences.remove(cacheKey);
    }
    return false;
  }

  Future<void> _saveLocalConversationWindow(List<MessageModel> input) async {
    try {
      final preferences = ensureLocalPreferenceRepository();
      final list = input.take(_localChatWindowLimit).toList();
      final payload = list.map(_serializeLocalMessage).toList();
      await preferences.setString(_localChatWindowKey, jsonEncode(payload));
    } catch (_) {}
  }

  Map<String, dynamic> _serializeLocalMessage(MessageModel m) {
    return {
      "docID": m.docID,
      "rawDocID": m.rawDocID,
      "source": m.source,
      "timeStamp": m.timeStamp,
      "userID": m.userID,
      "lat": m.lat,
      "long": m.long,
      "postType": m.postType,
      "postID": m.postID,
      "imgs": m.imgs,
      "video": m.video,
      "isRead": m.isRead,
      "kullanicilar": m.kullanicilar,
      "begeniler": m.begeniler,
      "metin": m.metin,
      "sesliMesaj": m.sesliMesaj,
      "kisiAdSoyad": m.kisiAdSoyad,
      "kisiTelefon": m.kisiTelefon,
      "isEdited": m.isEdited,
      "isUnsent": m.isUnsent,
      "isForwarded": m.isForwarded,
      "replyMessageId": m.replyMessageId,
      "replySenderId": m.replySenderId,
      "replyText": m.replyText,
      "replyType": m.replyType,
      "reactions": m.reactions,
      "status": m.status,
      "videoThumbnail": m.videoThumbnail,
      "audioDurationMs": m.audioDurationMs,
    };
  }

  MessageModel? _deserializeLocalMessage(Map<String, dynamic> data) {
    try {
      final docID = (data["docID"] ?? "").toString();
      final rawDocID = (data["rawDocID"] ?? "").toString().trim().isNotEmpty
          ? (data["rawDocID"] ?? "").toString()
          : docID.replaceFirst(RegExp(r'^conv_'), '');
      return MessageModel(
        docID: docID,
        rawDocID: rawDocID,
        source: (data["source"] ?? "conversation").toString(),
        timeStamp: data["timeStamp"] is num ? data["timeStamp"] as num : 0,
        userID: (data["userID"] ?? "").toString(),
        lat: data["lat"] is num ? data["lat"] as num : 0,
        long: data["long"] is num ? data["long"] as num : 0,
        postType: (data["postType"] ?? "").toString(),
        postID: (data["postID"] ?? "").toString(),
        imgs: List<String>.from(data["imgs"] ?? const []),
        video: (data["video"] ?? "").toString(),
        isRead: data["isRead"] == true,
        kullanicilar: List<String>.from(data["kullanicilar"] ?? const []),
        metin: (data["metin"] ?? "").toString(),
        sesliMesaj: (data["sesliMesaj"] ?? "").toString(),
        kisiAdSoyad: (data["kisiAdSoyad"] ?? "").toString(),
        kisiTelefon: (data["kisiTelefon"] ?? "").toString(),
        begeniler: List<String>.from(data["begeniler"] ?? const []),
        isEdited: data["isEdited"] == true,
        isUnsent: data["isUnsent"] == true,
        isForwarded: data["isForwarded"] == true,
        replyMessageId: (data["replyMessageId"] ?? "").toString(),
        replySenderId: (data["replySenderId"] ?? "").toString(),
        replyText: (data["replyText"] ?? "").toString(),
        replyType: (data["replyType"] ?? "").toString(),
        reactions: Map<String, List<String>>.from(
          (data["reactions"] as Map? ?? {}).map(
            (k, v) => MapEntry(
              k.toString(),
              List<String>.from(v ?? const []),
            ),
          ),
        ),
        status: (data["status"] ?? "").toString(),
        videoThumbnail: (data["videoThumbnail"] ?? "").toString(),
        audioDurationMs: data["audioDurationMs"] is num
            ? (data["audioDurationMs"] as num).toInt()
            : 0,
      );
    } catch (_) {
      return null;
    }
  }
}
