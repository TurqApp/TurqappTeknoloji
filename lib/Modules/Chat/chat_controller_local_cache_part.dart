part of 'chat_controller.dart';

extension ChatControllerLocalCachePart on ChatController {
  String get _localChatWindowKey {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return "chat_window_cache_guest_$chatID";
    return "chat_window_cache_${uid}_$chatID";
  }

  Future<bool> _loadLocalConversationWindow() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _localChatWindowKey;
    try {
      final raw = prefs.getString(cacheKey);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await prefs.remove(cacheKey);
        return false;
      }

      final restored = <MessageModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final m = _deserializeLocalMessage(Map<String, dynamic>.from(item));
        if (m != null) restored.add(m);
      }
      if (restored.isEmpty) {
        await prefs.remove(cacheKey);
        return false;
      }
      restored.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      _conversationMessages
        ..clear()
        ..addEntries(
          restored.map((message) => MapEntry(message.rawDocID, message)),
        );
      messages.value = restored;
      return true;
    } catch (_) {
      await prefs.remove(cacheKey);
    }
    return false;
  }

  Future<void> _saveLocalConversationWindow(List<MessageModel> input) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = input.take(_localChatWindowLimit).toList();
      final payload = list.map(_serializeLocalMessage).toList();
      await prefs.setString(_localChatWindowKey, jsonEncode(payload));
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
      return MessageModel(
        docID: (data["docID"] ?? "").toString(),
        rawDocID: (data["rawDocID"] ?? "").toString(),
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
