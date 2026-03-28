part of 'chat_controller.dart';

extension ChatControllerSendPart on ChatController {
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

    final now = DateTime.now();
    final sendPlan = await conversationApplicationService.prepareSendPlan(
      currentUid: CurrentUserService.instance.effectiveUserId,
      routeUserId: userID,
      chatId: chatID,
      now: now,
      text: text,
      imageUrls: imageUrls,
      latLng: latLng,
      kisiAdSoyad: kisiAdSoyad,
      kisiTelefon: kisiTelefon,
      gif: gif,
      postID: postID,
      postType: postType,
      videoUrl: videoUrl,
      videoThumbnail: videoThumbnail,
      audioUrl: audioUrl,
      audioDurationMs: audioDurationMs,
      replyTextOverride: replyTextOverride,
      replyTypeOverride: replyTypeOverride,
      replySenderIdOverride: replySenderIdOverride,
      replyMessageIdOverride: replyMessageIdOverride,
      replyingTo: replyingTo.value,
    );
    if (sendPlan == null) return;

    try {
      final currentUid = sendPlan.currentUid;
      await conversationApplicationService.ensureConversationReady(
        chatId: chatID,
        currentUid: currentUid,
        targetUserId: sendPlan.targetUidForConversation,
        previewText: sendPlan.previewText,
        nowMs: now.millisecondsSinceEpoch,
      );
      final addedRef = await _conversationRepository.addMessage(
        chatId: chatID,
        payload: Map<String, dynamic>.from(sendPlan.payload),
      );
      lastSentMessageId.value = addedRef.id;
      lastSentText.value = sendPlan.text;
      lastSentType.value = sendPlan.messageType;
      lastSentMediaCount.value = imageUrls?.length ?? 0;
      lastSentPrimaryMediaUrl.value = imageUrls?.isNotEmpty == true
          ? imageUrls!.first
          : (gif?.trim() ?? '');
      lastSentVideoUrl.value = videoUrl?.trim() ?? '';
      lastSentAudioUrl.value = audioUrl?.trim() ?? '';

      try {
        final optimistic = MessageModel.fromConversationData(
          sendPlan.payload,
          addedRef.id,
        );
        _conversationMessages[optimistic.docID] = optimistic;
        _refreshMergedMessages();
      } catch (_) {
        ChatControllerSupportPart(this)._syncMessages(forceServer: true);
      }

      if (!_recipientMuted &&
          sendPlan.resolvedTargetUid != null &&
          sendPlan.resolvedTargetUid!.isNotEmpty &&
          sendPlan.resolvedTargetUid != currentUid) {
        try {
          final convMeta = await _conversationRepository.getConversation(
            chatID,
            preferCache: true,
            cacheOnly: false,
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
          final marketNotified =
              await MarketNotificationService.notifyConversationMessageIfNeeded(
            targetUserId: sendPlan.resolvedTargetUid!,
            chatId: chatID,
            conversationData: convMeta,
          );
          if (!marketNotified) {
            NotificationService.instance.sendNotification(
              token: "",
              title: senderLabel,
              body: sendPlan.notificationBody,
              docID: chatID,
              type: kNotificationPostTypeChat,
              targetUserID: sendPlan.resolvedTargetUid!,
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
