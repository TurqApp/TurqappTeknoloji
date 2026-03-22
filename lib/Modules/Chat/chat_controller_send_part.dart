part of 'chat_controller.dart';

extension ChatControllerSendPart on ChatController {
  Future<String?> _resolveCounterpartUserId() async {
    final currentUid = CurrentUserService.instance.effectiveUserId.trim();
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

  Future<void> _ensureConversationReady({
    required String targetUserId,
    required String previewText,
    required int nowMs,
  }) async {
    final currentUid = CurrentUserService.instance.effectiveUserId;
    if (currentUid.isEmpty) return;
    await _conversationRepository.upsertConversationEnvelope(
      chatId: chatID,
      currentUid: currentUid,
      otherUid: targetUserId,
      lastMessage: previewText,
      nowMs: nowMs,
    );
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
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.sendMessage)) {
      return;
    }
    final text = (textOverride ?? textEditingController.text).trim();

    if (text.isNotEmpty && kufurKontrolEt(text)) {
      AppSnackbar(
        'comments.community_violation_title'.tr,
        'comments.community_violation_body'.tr,
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

    if (text.isEmpty &&
        !(imageUrls?.isNotEmpty ?? false) &&
        latLng == null &&
        !(kisiAdSoyad?.isNotEmpty ?? false) &&
        !(postID?.isNotEmpty ?? false) &&
        !(gif?.isNotEmpty ?? false) &&
        !(videoUrl?.isNotEmpty ?? false) &&
        !(audioUrl?.isNotEmpty ?? false)) {
      return;
    }

    String notifBody;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      notifBody = 'chat.notif_video'.tr;
    } else if (audioUrl != null && audioUrl.isNotEmpty) {
      notifBody = 'chat.notif_audio'.tr;
    } else if (imageUrls != null && imageUrls.isNotEmpty) {
      notifBody = 'chat.notif_images'.trParams({
        'count': imageUrls.length.toString(),
      });
    } else if (postID != null && postID.isNotEmpty) {
      notifBody = 'chat.notif_post'.tr;
    } else if (latLng != null) {
      notifBody = 'chat.notif_location'.tr;
    } else if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty) {
      notifBody = 'chat.notif_contact'.tr;
    } else if (gif != null && gif.isNotEmpty) {
      notifBody = 'chat.notif_gif'.tr;
    } else {
      notifBody = text;
    }

    final now = DateTime.now();
    final hasExternalReply = (replyTextOverride ?? "").trim().isNotEmpty;
    final replyTextFinal = (replyTextOverride ?? "").trim();
    final replyTypeFinal = (replyTypeOverride ?? "text").trim();
    final replySenderFinal =
        (replySenderIdOverride ?? CurrentUserService.instance.effectiveUserId)
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
        inferredReplyText = "🎥 ${'chat.video'.tr}";
        inferredReplyTarget = repliedModel.video;
      } else if (repliedModel.imgs.isNotEmpty) {
        inferredReplyType = "media";
        inferredReplyText = "📷 ${'chat.photo'.tr}";
        inferredReplyTarget = repliedModel.imgs.first;
      } else if (repliedModel.sesliMesaj.isNotEmpty) {
        inferredReplyType = "audio";
        inferredReplyText = "🎤 ${'chat.audio'.tr}";
      } else if (repliedModel.lat != 0 || repliedModel.long != 0) {
        inferredReplyType = "location";
        inferredReplyText = "📍 ${'chat.location'.tr}";
      } else if (repliedModel.postID.trim().isNotEmpty) {
        inferredReplyType = "post";
        inferredReplyText = "🔗 ${'chat.post'.tr}";
        inferredReplyTarget = repliedModel.postID.trim();
      } else if (repliedModel.kisiAdSoyad.trim().isNotEmpty) {
        inferredReplyType = "contact";
        inferredReplyText = "👤 ${'chat.person'.tr}";
      } else {
        inferredReplyType = "text";
        inferredReplyText = repliedModel.metin.trim().isNotEmpty
            ? repliedModel.metin
            : 'chat.message_hint'.tr;
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
      "senderId": CurrentUserService.instance.effectiveUserId,
      "text": text,
      "createdDate": now.millisecondsSinceEpoch,
      "seenBy": [CurrentUserService.instance.effectiveUserId],
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
      final currentUid = CurrentUserService.instance.effectiveUserId;
      final resolvedTargetUid = await _resolveCounterpartUserId();
      final targetUidForConversation = resolvedTargetUid ?? userID;
      await _ensureConversationReady(
        targetUserId: targetUidForConversation,
        previewText: previewText,
        nowMs: now.millisecondsSinceEpoch,
      );
      final addedRef = await _conversationRepository.addMessage(
        chatId: chatID,
        payload: Map<String, dynamic>.from(conversationMessageData),
      );
      lastSentMessageId.value = addedRef.id;
      lastSentText.value = text;
      lastSentType.value = messageType;
      lastSentMediaCount.value = imageUrls?.length ?? 0;
      lastSentPrimaryMediaUrl.value = imageUrls?.isNotEmpty == true
          ? imageUrls!.first
          : (gif?.trim() ?? '');
      lastSentVideoUrl.value = videoUrl?.trim() ?? '';
      lastSentAudioUrl.value = audioUrl?.trim() ?? '';

      try {
        final optimistic = MessageModel.fromConversationData(
          conversationMessageData,
          addedRef.id,
        );
        _conversationMessages[optimistic.docID] = optimistic;
        _refreshMergedMessages();
      } catch (_) {
        _syncMessages(forceServer: true);
      }

      if (!_recipientMuted &&
          resolvedTargetUid != null &&
          resolvedTargetUid.isNotEmpty &&
          resolvedTargetUid != currentUid) {
        try {
          final convMeta = await _conversationRepository.getConversation(
            chatID,
            preferCache: true,
            cacheOnly: false,
          );
          final marketContext = Map<String, dynamic>.from(
            convMeta?['marketContext'] as Map? ?? const <String, dynamic>{},
          );
          final senderLabel = (() {
            final full = CurrentUserService.instance.fullName.trim();
            if (full.isNotEmpty) return full;
            final nick = CurrentUserService.instance.nickname.trim();
            if (nick.isNotEmpty) return nick;
            final authName = CurrentUserService.instance.authDisplayName;
            if (authName.isNotEmpty) return authName;
            return 'app.name'.tr;
          })();
          final marketItemId = (marketContext['itemId'] ?? '').toString();
          if (marketItemId.isNotEmpty) {
            await MarketNotificationService.notifyMarketMessage(
              targetUserId: resolvedTargetUid,
              chatId: chatID,
              sellerId: (marketContext['sellerId'] ?? '').toString(),
              itemId: marketItemId,
              itemTitle: (marketContext['title'] ?? '').toString(),
              coverImageUrl: (marketContext['coverImageUrl'] ?? '').toString(),
            );
          } else {
            NotificationService.instance.sendNotification(
              token: "",
              title: senderLabel,
              body: notifBody,
              docID: chatID,
              type: kNotificationPostTypeChat,
              targetUserID: resolvedTargetUid,
            );
          }
        } catch (_) {}
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'chat.message_send_failed'.tr);
    }

    if (textOverride == null) {
      textEditingController.clear();
    }
    clearComposerAction();
    ChatListingController.maybeFind()?.getList();
  }
}
