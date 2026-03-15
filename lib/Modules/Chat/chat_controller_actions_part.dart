part of 'chat_controller.dart';

extension ChatControllerActionsPart on ChatController {
  void startReply(MessageModel model) {
    replyingTo.value = model;
    editingMessage.value = null;
    focus.requestFocus();
  }

  void startEdit(MessageModel model) {
    if (model.userID != FirebaseAuth.instance.currentUser!.uid) return;
    if (model.metin.trim().isEmpty) return;
    editingMessage.value = model;
    replyingTo.value = null;
    textEditingController.text = model.metin;
    textMesage.value = model.metin;
    focus.requestFocus();
  }

  void clearComposerAction() {
    replyingTo.value = null;
    editingMessage.value = null;
    selectedGifUrl.value = '';
  }

  Future<void> pickGif(BuildContext context) async {
    final url = await GiphyPickerService.pickGifUrl(
      context,
      randomId: 'turqapp_chat_$chatID',
    );
    if (url != null && url.trim().isNotEmpty) {
      selectedGifUrl.value = url.trim();
      focus.unfocus();
    }
  }

  void startSelectionMode([String? rawId]) {
    isSelectionMode.value = true;
    if (rawId != null && rawId.isNotEmpty) {
      toggleSelection(rawId);
    }
  }

  void stopSelectionMode() {
    isSelectionMode.value = false;
    selectedMessageIds.clear();
  }

  void toggleSelection(String rawId) {
    if (rawId.isEmpty) return;
    final next = Set<String>.from(selectedMessageIds);
    if (next.contains(rawId)) {
      next.remove(rawId);
    } else {
      next.add(rawId);
    }
    selectedMessageIds
      ..clear()
      ..addAll(next);
    if (selectedMessageIds.isEmpty) {
      isSelectionMode.value = false;
    } else {
      isSelectionMode.value = true;
    }
  }

  void toggleStarredFilter() {
    showStarredOnly.value = !showStarredOnly.value;
  }

  List<MessageModel> get filteredMessages {
    if (!showStarredOnly.value) return messages;
    return messages.where((m) => m.isStarred).toList();
  }

  Future<void> toggleStarMessage(MessageModel model) async {
    try {
      final convRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatID);
      final msgRef = convRef.collection("messages").doc(model.rawDocID);
      await msgRef.set({
        "isStarred": !model.isStarred,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteSelectedMessages() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedMessageIds.isEmpty) return;
    try {
      final convRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatID);
      final batch = FirebaseFirestore.instance.batch();
      for (final rawId in selectedMessageIds) {
        final ref = convRef.collection("messages").doc(rawId);
        batch.set(
          ref,
          {
            "deletedFor": FieldValue.arrayUnion([uid])
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      final toRemove = Set<String>.from(selectedMessageIds);
      _conversationMessages
          .removeWhere((_, m) => toRemove.contains(m.rawDocID));
      selectedMessageIds.clear();
      isSelectionMode.value = false;
      _refreshMergedMessages();
    } catch (e) {
      AppSnackbar("Hata", "Mesajlar silinemedi");
    }
  }

  void _applyConversationSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool replace,
  }) {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    if (replace) _conversationMessages.clear();
    final List<String> unseenRawDocIds = [];
    final List<String> undeliveredRawDocIds = [];
    int latestSeenTs = 0;

    for (final doc in docs) {
      final data = doc.data();
      final senderId = data["senderId"] ?? "";
      final deletedFor = List<String>.from(data["deletedFor"] ?? []);
      if (deletedFor.contains(currentUID)) {
        _conversationMessages.remove("conv_${doc.id}");
        continue;
      }
      final status = data["status"] ?? "";
      final seenBy = List<String>.from(data["seenBy"] ?? []);
      final model = MessageModel.fromConversationSnapshot(doc);
      _conversationMessages[model.docID] = model;
      final ts = model.timeStamp.toInt();
      if (ts > latestSeenTs) latestSeenTs = ts;

      if (senderId != currentUID && !seenBy.contains(currentUID)) {
        unseenRawDocIds.add(doc.id);
      }

      // Mark other user's "sent" messages as "delivered" when we see them
      if (senderId != currentUID && status == "sent") {
        undeliveredRawDocIds.add(doc.id);
      }
    }

    final convRef =
        FirebaseFirestore.instance.collection("conversations").doc(chatID);

    if (unseenRawDocIds.isNotEmpty || undeliveredRawDocIds.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final rawId in unseenRawDocIds.take(25)) {
        final msgRef = convRef.collection("messages").doc(rawId);
        batch.update(msgRef, {
          "seenBy": FieldValue.arrayUnion([currentUID]),
          "status": "read",
        });
      }
      for (final rawId in undeliveredRawDocIds.take(25)) {
        if (!unseenRawDocIds.contains(rawId)) {
          final msgRef = convRef.collection("messages").doc(rawId);
          batch.update(msgRef, {"status": "delivered"});
        }
      }
      batch.commit().then((_) {
        return _conversationRepository.setUnreadCount(
          chatId: chatID,
          currentUid: currentUID,
          unreadCount: 0,
        );
      }).catchError((_) => null);
    }

    if (latestSeenTs > 0) {
      unawaited(_markConversationOpenedAt(latestSeenTs));
    }
  }

  void _refreshMergedMessages() {
    final merged = <MessageModel>[..._conversationMessages.values];
    merged.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    messages.value = merged;
    unawaited(_saveLocalConversationWindow(merged));
  }

  String get _localChatWindowKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return "chat_window_cache_guest_$chatID";
    return "chat_window_cache_${uid}_$chatID";
  }

  Future<bool> _loadLocalConversationWindow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localChatWindowKey);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;

      final restored = <MessageModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final m = _deserializeLocalMessage(Map<String, dynamic>.from(item));
        if (m != null) restored.add(m);
      }
      if (restored.isEmpty) return false;
      restored.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      messages.value = restored;
      return true;
    } catch (_) {}
    return false;
  }

  Future<void> _saveLocalConversationWindow(List<MessageModel> input) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = input.take(ChatController._localChatWindowLimit).toList();
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

  Future<String?> _resolveCounterpartUserId() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (currentUid.isEmpty) return null;

    final candidates = <String>{};
    final fromParam = userID.trim();
    if (fromParam.isNotEmpty) candidates.add(fromParam);

    final parts = chatID.split("_");
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) candidates.add(trimmed);
    }

    try {
      final data = await _conversationRepository.getConversation(
        chatID,
        preferCache: true,
        cacheOnly: false,
      );
      if (data != null) {
        final participants = data["participants"];
        if (participants is List) {
          for (final p in participants) {
            final uid = p.toString().trim();
            if (uid.isNotEmpty) candidates.add(uid);
          }
        }
        final uid1 = (data["userID1"] ?? "").toString().trim();
        final uid2 = (data["userID2"] ?? "").toString().trim();
        if (uid1.isNotEmpty) candidates.add(uid1);
        if (uid2.isNotEmpty) candidates.add(uid2);
      }
    } catch (_) {}

    for (final uid in candidates) {
      if (uid != currentUid) return uid;
    }
    return null;
  }

  Map<String, int> _sanitizeUnreadMap(
    dynamic raw,
    List<String> participants,
  ) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, int>{};
    for (final uid in participants) {
      final value = source[uid];
      if (value is int) {
        result[uid] = value < 0 ? 0 : value;
      } else if (value is num) {
        final parsed = value.toInt();
        result[uid] = parsed < 0 ? 0 : parsed;
      } else if (value is String) {
        final parsed = int.tryParse(value) ?? 0;
        result[uid] = parsed < 0 ? 0 : parsed;
      } else {
        result[uid] = 0;
      }
    }
    return result;
  }

  Map<String, bool> _sanitizeBoolParticipantMap(
    dynamic raw,
    List<String> participants, {
    bool defaultValue = false,
  }) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, bool>{};
    for (final uid in participants) {
      final value = source[uid];
      if (value is bool) {
        result[uid] = value;
      } else if (value is num) {
        result[uid] = value != 0;
      } else {
        result[uid] = defaultValue;
      }
    }
    return result;
  }

  Map<String, int> _sanitizeIntParticipantMap(
    dynamic raw,
    List<String> participants, {
    int defaultValue = 0,
    bool nonNegative = true,
  }) {
    final source = raw is Map ? raw : const <String, dynamic>{};
    final result = <String, int>{};
    for (final uid in participants) {
      final value = source[uid];
      int parsed;
      if (value is int) {
        parsed = value;
      } else if (value is num) {
        parsed = value.toInt();
      } else if (value is String) {
        parsed = int.tryParse(value) ?? defaultValue;
      } else {
        parsed = defaultValue;
      }
      if (nonNegative && parsed < 0) parsed = 0;
      result[uid] = parsed;
    }
    return result;
  }

  Future<void> _ensureConversationReady({
    required String targetUserId,
    required String previewText,
    required int nowMs,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final participants = [currentUid, targetUserId]..sort();
    final convRef =
        FirebaseFirestore.instance.collection("conversations").doc(chatID);
    final convData = await _conversationRepository.getConversation(
      chatID,
      preferCache: true,
      cacheOnly: false,
    );

    if (convData == null) {
      await convRef.set({
        "participants": participants,
        "userID1": participants.first,
        "userID2": participants.last,
        "lastMessage": previewText,
        "lastMessageAt": nowMs,
        "lastMessageAtMs": nowMs,
        "lastSenderId": currentUid,
        "archived": {
          currentUid: false,
          targetUserId: false,
        },
        "unread": {
          currentUid: 0,
          targetUserId: 1,
        },
        "typing": {
          currentUid: 0,
          targetUserId: 0,
        },
        "muted": {
          currentUid: false,
          targetUserId: false,
        },
        "pinned": {
          currentUid: false,
          targetUserId: false,
        },
        "chatBg": {
          currentUid: 0,
          targetUserId: 0,
        },
      });
      return;
    }

    final data = convData;
    final existingParticipants = data["participants"] is List
        ? List<String>.from(
            (data["participants"] as List).map((e) => e.toString()),
          )
        : <String>[];
    final hasCanonicalParticipants = existingParticipants.length == 2 &&
        existingParticipants.contains(currentUid) &&
        existingParticipants.contains(targetUserId);

    final unread = _sanitizeUnreadMap(data["unread"], participants);
    unread[currentUid] = 0;
    unread[targetUserId] = (unread[targetUserId] ?? 0) + 1;
    final archived = _sanitizeBoolParticipantMap(
      data["archived"],
      participants,
      defaultValue: false,
    );
    archived[currentUid] = false;
    archived[targetUserId] = false;
    final typing = _sanitizeIntParticipantMap(
      data["typing"],
      participants,
      defaultValue: 0,
      nonNegative: true,
    );
    final muted = _sanitizeBoolParticipantMap(
      data["muted"],
      participants,
      defaultValue: false,
    );
    final pinned = _sanitizeBoolParticipantMap(
      data["pinned"],
      participants,
      defaultValue: false,
    );
    final chatBg = _sanitizeIntParticipantMap(
      data["chatBg"],
      participants,
      defaultValue: 0,
      nonNegative: true,
    );

    await convRef.set({
      if (!hasCanonicalParticipants) "participants": participants,
      if (!hasCanonicalParticipants) "userID1": participants.first,
      if (!hasCanonicalParticipants) "userID2": participants.last,
      "lastMessage": previewText,
      "lastMessageAt": nowMs,
      "lastMessageAtMs": nowMs,
      "lastSenderId": currentUid,
      "archived": archived,
      "unread": unread,
      "typing": typing,
      "muted": muted,
      "pinned": pinned,
      "chatBg": chatBg,
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    List<String>? imageUrls,
    LatLng? latLng,
    String? kisiAdSoyad,
    String? kisiTelefon,
    String? gif,
    String? postID,
    String? postType,
    String? videoUrl,
    String? videoThumbnail,
    String? audioUrl,
    int? audioDurationMs,
    String? textOverride,
    String? replyTextOverride,
    String? replyTypeOverride,
    String? replySenderIdOverride,
    String? replyMessageIdOverride,
  }) async {
    final text = (textOverride ?? textEditingController.text).trim();

    // 1. Küfür kontrolü
    if (text.isNotEmpty && kufurKontrolEt(text)) {
      AppSnackbar(
        "Topluluk Kurallarına Aykırı",
        "Göndermeye çalıştığınız mesaj uygunsuz içerik içeriyor. Lütfen saygılı bir dil kullanın.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }

    if (editingMessage.value != null) {
      final editing = editingMessage.value!;
      if (text.isEmpty) return;
      await _editMessage(editing, text);
      textEditingController.clear();
      textMesage.value = "";
      editingMessage.value = null;
      return;
    }

    // 2. Mesaj koşulları
    if (text.isNotEmpty ||
        (imageUrls?.isNotEmpty ?? false) ||
        latLng != null ||
        (kisiAdSoyad?.isNotEmpty ?? false) ||
        (postID?.isNotEmpty ?? false) ||
        (gif?.isNotEmpty ?? false) ||
        (videoUrl?.isNotEmpty ?? false) ||
        (audioUrl?.isNotEmpty ?? false)) {
      // Notif body
      String notifBody;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        notifBody = "Bir video gönderdi";
      } else if (audioUrl != null && audioUrl.isNotEmpty) {
        notifBody = "Sesli mesaj gönderdi";
      } else if (imageUrls != null && imageUrls.isNotEmpty) {
        notifBody = "${imageUrls.length} adet resim gönderdi";
      } else if (postID != null && postID.isNotEmpty) {
        notifBody = "Bir gönderi paylaştı";
      } else if (latLng != null) {
        notifBody = "Bir konum gönderdi";
      } else if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty) {
        notifBody = "Bir rehber bilgisi paylaştı";
      } else if (gif != null && gif.isNotEmpty) {
        notifBody = "Bir GIF gönderdi";
      } else {
        notifBody = text;
      }

      final now = DateTime.now();
      final hasExternalReply = (replyTextOverride ?? "").trim().isNotEmpty;
      final replyTextFinal = (replyTextOverride ?? "").trim();
      final replyTypeFinal = (replyTypeOverride ?? "text").trim();
      final replySenderFinal =
          (replySenderIdOverride ?? FirebaseAuth.instance.currentUser!.uid)
              .trim();
      final replyMessageFinal =
          (replyMessageIdOverride ?? "preview_${now.microsecondsSinceEpoch}")
              .trim();

      String inferredReplyText = "";
      String inferredReplyType = "text";
      String inferredReplyTarget = "";
      final repliedModel = replyingTo.value;
      if (!hasExternalReply && repliedModel != null) {
        inferredReplyTarget = repliedModel.rawDocID;
        if (repliedModel.video.isNotEmpty) {
          inferredReplyType = "video";
          inferredReplyText = "🎥 Video";
          inferredReplyTarget = repliedModel.video;
        } else if (repliedModel.imgs.isNotEmpty) {
          inferredReplyType = "media";
          inferredReplyText = "📷 Fotoğraf";
          inferredReplyTarget = repliedModel.imgs.first;
        } else if (repliedModel.sesliMesaj.isNotEmpty) {
          inferredReplyType = "audio";
          inferredReplyText = "🎤 Ses";
        } else if (repliedModel.lat != 0 || repliedModel.long != 0) {
          inferredReplyType = "location";
          inferredReplyText = "📍 Konum";
        } else if (repliedModel.postID.trim().isNotEmpty) {
          inferredReplyType = "post";
          inferredReplyText = "🔗 Gönderi";
          inferredReplyTarget = repliedModel.postID.trim();
        } else if (repliedModel.kisiAdSoyad.trim().isNotEmpty) {
          inferredReplyType = "contact";
          inferredReplyText = "👤 Kişi";
        } else {
          inferredReplyType = "text";
          inferredReplyText = repliedModel.metin.trim().isNotEmpty
              ? repliedModel.metin
              : "Mesaj";
        }
      }

      final messageType = _resolveMessageType(
        text: text,
        imageUrls: imageUrls,
        latLng: latLng,
        kisiAdSoyad: kisiAdSoyad,
        postID: postID,
        gif: gif,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
      );

      final conversationMessageData = {
        "senderId": FirebaseAuth.instance.currentUser!.uid,
        "text": text,
        "createdDate": now.millisecondsSinceEpoch,
        "seenBy": [FirebaseAuth.instance.currentUser!.uid],
        "type": messageType,
        "mediaUrls": gif != null ? [gif] : (imageUrls ?? []),
        "likes": <String>[],
        "isDeleted": false,
        "isEdited": false,
        "forwarded": false,
        "unsent": false,
        "audioUrl": audioUrl ?? "",
        "audioDurationMs": audioDurationMs ?? 0,
        "videoUrl": videoUrl ?? "",
        "videoThumbnail": videoThumbnail ?? "",
        "status": "sent",
        "reactions": <String, List<String>>{},
        if (latLng != null)
          "location": {
            "lat": latLng.latitude.toDouble(),
            "lng": latLng.longitude.toDouble(),
            "name": text,
          },
        if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty)
          "contact": {
            "name": kisiAdSoyad,
            "phone": kisiTelefon ?? "",
          },
        if (postID != null && postID.isNotEmpty)
          "postRef": {
            "postId": postID,
            "postType": postType ?? "",
            "previewText": "",
            "previewImageUrl": "",
          },
        if (hasExternalReply)
          "replyTo": {
            "messageId": replyMessageFinal,
            "senderId": replySenderFinal,
            "text": replyTextFinal,
            "type": replyTypeFinal.isEmpty ? "text" : replyTypeFinal,
          },
        if (!hasExternalReply && replyingTo.value != null)
          "replyTo": {
            "messageId": inferredReplyTarget,
            "senderId": replyingTo.value!.userID,
            "text": inferredReplyText,
            "type": inferredReplyType,
          },
      };

      final previewText = _buildLastMessageText(
        text: text,
        imageUrls: imageUrls,
        latLng: latLng,
        kisiAdSoyad: kisiAdSoyad,
        postID: postID,
        gif: gif,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
      );

      try {
        final currentUid = FirebaseAuth.instance.currentUser!.uid;
        final resolvedTargetUid = await _resolveCounterpartUserId();
        final targetUidForConversation = resolvedTargetUid ?? userID;
        final convRef =
            FirebaseFirestore.instance.collection("conversations").doc(chatID);
        await _ensureConversationReady(
          targetUserId: targetUidForConversation,
          previewText: previewText,
          nowMs: now.millisecondsSinceEpoch,
        );
        final addedRef =
            await convRef.collection("messages").add(conversationMessageData);

        // Anında UI güncellemesi: sunucu sync beklemeden mesaj listesine düşür.
        try {
          final optimistic = MessageModel.fromConversationData(
            conversationMessageData,
            addedRef.id,
          );
          _conversationMessages[optimistic.docID] = optimistic;
          _refreshMergedMessages();
        } catch (_) {
          // Optimistic UI başarısız olsa bile mesaj gönderildi, sync ile gelecek.
          _syncMessages(forceServer: true);
        }

        // Notifikasyon gönder (hata olursa mesaj zaten gönderildi)
        if (!_recipientMuted &&
            resolvedTargetUid != null &&
            resolvedTargetUid.isNotEmpty &&
            resolvedTargetUid != currentUid) {
          try {
            NotificationService.instance.sendNotification(
              token: "",
              title: nickname.value,
              body: notifBody,
              docID: chatID,
              type: "Chat",
              targetUserID: resolvedTargetUid,
            );
          } catch (_) {}
        }
      } catch (_) {
        AppSnackbar("Hata", "Mesaj gönderilemedi. Lütfen tekrar dene.");
      }

      if (textOverride == null) {
        textEditingController.clear();
      }
      clearComposerAction();
      if (Get.isRegistered<ChatListingController>()) {
        Get.find<ChatListingController>().getList();
      }
    }
  }
}
