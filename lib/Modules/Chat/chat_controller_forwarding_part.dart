part of 'chat_controller.dart';

extension ChatControllerForwardingPart on ChatController {
  Future<void> sendExternalText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await sendMessage(textOverride: clean);
  }

  Future<void> sendExternalReplyText(
    String text, {
    required String replyText,
    required String replyType,
    required String replyTarget,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await sendMessage(
      textOverride: clean,
      replyTextOverride: replyText,
      replyTypeOverride: replyType,
      replySenderIdOverride: CurrentUserService.instance.userId,
      replyMessageIdOverride: replyTarget,
    );
  }

  Future<void> toggleReaction(MessageModel model, String emoji) async {
    final uid = CurrentUserService.instance.userId;
    final ref = FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .doc(model.rawDocID);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final reactions = Map<String, dynamic>.from(data["reactions"] ?? {});
      final selectedUsers = List<String>.from(reactions[emoji] ?? const []);
      final wasSelected = selectedUsers.contains(uid);

      final updates = <String, dynamic>{};

      // Tek emoji kuralı: kullanıcıyı önce tüm reaction listelerinden kaldır.
      for (final entry in reactions.entries) {
        final key = entry.key.toString();
        final users = List<String>.from(entry.value ?? const []);
        if (users.contains(uid)) {
          updates["reactions.$key"] = FieldValue.arrayRemove([uid]);
        }
      }

      // Aynı emojiyse toggle-off, farklı emojiyse sadece seçilen emojiye ekle.
      if (!wasSelected) {
        updates["reactions.$emoji"] = FieldValue.arrayUnion([uid]);
      }

      tx.update(ref, updates);
    });
  }

  Future<void> unsendMessage(MessageModel model) async {
    final currentUID = CurrentUserService.instance.userId;
    if (model.userID != currentUID) return;

    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .doc(model.rawDocID)
        .update({
      "unsent": true,
      "text": "",
      "mediaUrls": <String>[],
      "location": FieldValue.delete(),
      "contact": FieldValue.delete(),
      "postRef": FieldValue.delete(),
    });
  }

  Future<void> _editMessage(MessageModel model, String newText) async {
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .doc(model.rawDocID)
        .update({
      "text": newText,
      "isEdited": true,
    });
  }

  Future<void> openForwardPicker(MessageModel model) async {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    final docs = await _conversationRepository.fetchUserConversations(
      currentUID,
      preferCache: true,
      cacheOnly: false,
    );
    final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      docs,
    )..sort((a, b) {
        final aTs = ((a.data()["lastMessageAt"] ?? 0) as num).toInt();
        final bTs = ((b.data()["lastMessageAt"] ?? 0) as num).toInt();
        return bTs.compareTo(aTs);
      });
    final snapDocs = sortedDocs.take(30).toList(growable: false);

    final items = <Map<String, String>>[];
    final otherIds = <String>[];
    for (final doc in snapDocs) {
      if (doc.id == chatID) continue;
      final participants = List<String>.from(doc.data()["participants"] ?? []);
      final other = participants.firstWhereOrNull((v) => v != currentUID);
      if (other == null || other.isEmpty) continue;
      otherIds.add(other);
    }

    final userMap = await _userSummaryResolver.resolveMany(otherIds);
    for (final doc in snapDocs) {
      if (doc.id == chatID) continue;
      final participants = List<String>.from(doc.data()["participants"] ?? []);
      final other = participants.firstWhereOrNull((v) => v != currentUID);
      if (other == null || other.isEmpty) continue;
      final userData = userMap[other];
      if (userData == null) continue;
      items.add({
        "chatID": doc.id,
        "userID": other,
        "nickname": userData.preferredName,
      });
    }

    if (items.isEmpty) {
      AppSnackbar("common.info".tr, "chat.forward_target_missing".tr);
      return;
    }

    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: Colors.white,
          child: ListView(
            shrinkWrap: true,
            children: items
                .map(
                  (e) => ListTile(
                    title: Text(
                      e["nickname"] ?? "",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                    onTap: () async {
                      Get.back();
                      await forwardMessage(model, e["chatID"]!, e["userID"]!);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> forwardMessage(
      MessageModel model, String targetChatId, String targetUserId) async {
    final currentUID = FirebaseAuth.instance.currentUser!.uid;

    final convMessage = {
      "senderId": currentUID,
      "text": model.metin,
      "createdDate": DateTime.now().millisecondsSinceEpoch,
      "seenBy": [currentUID],
      "type": model.postID.isNotEmpty
          ? "post"
          : model.kisiAdSoyad.isNotEmpty
              ? "contact"
              : model.lat != 0
                  ? "location"
                  : model.imgs.isNotEmpty
                      ? "media"
                      : "text",
      "mediaUrls": model.imgs,
      "likes": <String>[],
      "isDeleted": false,
      "isEdited": false,
      "forwarded": true,
      "unsent": false,
      "reactions": <String, List<String>>{},
      if (model.kisiAdSoyad.isNotEmpty)
        "contact": {
          "name": model.kisiAdSoyad,
          "phone": model.kisiTelefon,
        },
      if (model.lat != 0)
        "location": {
          "lat": model.lat,
          "lng": model.long,
          "name": model.metin,
        },
      if (model.postID.isNotEmpty)
        "postRef": {
          "postId": model.postID,
          "postType": model.postType,
          "previewText": "",
          "previewImageUrl": "",
        },
      "forwardedFrom": {
        "conversationId": chatID,
        "messageId": model.rawDocID,
        "senderName": nickname.value,
      }
    };

    final previewText =
        model.metin.isNotEmpty ? model.metin : 'chat.forwarded_body'.tr;
    final convRef = FirebaseFirestore.instance
        .collection("conversations")
        .doc(targetChatId);
    final participants = [currentUID, targetUserId]..sort();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final convData = await _conversationRepository.getConversation(
      targetChatId,
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
        "lastSenderId": currentUID,
        "archived": {
          currentUID: false,
          targetUserId: false,
        },
        "unread": {
          currentUID: 0,
          targetUserId: 1,
        },
        "typing": {
          currentUID: 0,
          targetUserId: 0,
        },
        "muted": {
          currentUID: false,
          targetUserId: false,
        },
        "pinned": {
          currentUID: false,
          targetUserId: false,
        },
        "chatBg": {
          currentUID: 0,
          targetUserId: 0,
        },
      });
    } else {
      final data = convData;
      final existingParticipants = data["participants"] is List
          ? List<String>.from(
              (data["participants"] as List).map((e) => e.toString()),
            )
          : <String>[];
      final hasCanonicalParticipants = existingParticipants.length == 2 &&
          existingParticipants.contains(currentUID) &&
          existingParticipants.contains(targetUserId);
      final unread = _sanitizeUnreadMap(data["unread"], participants);
      unread[currentUID] = 0;
      unread[targetUserId] = (unread[targetUserId] ?? 0) + 1;
      final archived = _sanitizeBoolParticipantMap(
        data["archived"],
        participants,
        defaultValue: false,
      );
      archived[currentUID] = false;
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
        "lastSenderId": currentUID,
        "archived": archived,
        "unread": unread,
        "typing": typing,
        "muted": muted,
        "pinned": pinned,
        "chatBg": chatBg,
      }, SetOptions(merge: true));
    }

    await convRef.collection("messages").add(convMessage);

    AppSnackbar('chat.forwarded_title'.tr, 'chat.forwarded_body'.tr);
    if (Get.isRegistered<ChatListingController>()) {
      Get.find<ChatListingController>().getList();
    }
  }
}
