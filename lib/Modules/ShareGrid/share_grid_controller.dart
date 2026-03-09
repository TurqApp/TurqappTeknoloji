import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';

import '../Chat/ChatListing/chat_listing_controller.dart';

class ShareGridController extends GetxController {
  String postID;
  String postType;
  ShareGridController({required this.postType, required this.postID});
  TextEditingController search = TextEditingController();
  RxList<OgrenciModel> followings = <OgrenciModel>[].obs;
  var selectedUser = Rx<OgrenciModel?>(null);
  Rx<FocusNode> searchFocus = FocusNode().obs;
  final chatListingController = Get.put(ChatListingController());

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

  @override
  void onInit() {
    super.onInit();
    searchFocus.value.addListener(() => searchFocus.refresh());
    getFolowers();
  }

  Future<void> getFolowers() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("followings")
        .orderBy("timeStamp")
        .limit(20)
        .get()
        .then((snap) {
      for (var item in snap.docs) {
        FirebaseFirestore.instance
            .collection("users")
            .doc(item.id)
            .get()
            .then((doc) {
          final data = doc.data() ?? <String, dynamic>{};
          final nickname = (data["nickname"] ?? "").toString();
          final avatarUrl = (data["avatarUrl"] ?? "").toString();
          final firstName = (data["firstName"] ?? "").toString();
          final lastName = (data["lastName"] ?? "").toString();

          followings.add(OgrenciModel(
              userID: item.id,
              firstName: firstName,
              avatarUrl: avatarUrl,
              lastName: lastName,
              nickname: nickname));
        });
      }
    });
  }

  Future<void> sendIt() async {
    final selected = selectedUser.value;
    if (selected == null) {
      AppSnackbar("Uyarı", "Önce bir kullanıcı seç");
      return;
    }
    final userID = selected.userID;
    final sohbet = chatListingController.list.firstWhereOrNull(
      (val) => val.userID == userID,
    );
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    final chatId = sohbet?.chatID ?? buildConversationId(currentUID, userID);

    try {
      final conversationRef =
          FirebaseFirestore.instance.collection("conversations").doc(chatId);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final existing = await conversationRef.get();
      final participants = [currentUID, userID]..sort();

      if (!existing.exists) {
        await conversationRef.set({
          "participants": participants,
          "userID1": participants.first,
          "userID2": participants.last,
          "lastMessage": "Gönderi",
          "lastMessageAt": nowMs,
          "lastMessageAtMs": nowMs,
          "lastSenderId": currentUID,
          "archived": {
            currentUID: false,
            userID: false,
          },
          "unread": {
            currentUID: 0,
            userID: 1,
          },
          "typing": {
            currentUID: 0,
            userID: 0,
          },
          "muted": {
            currentUID: false,
            userID: false,
          },
          "pinned": {
            currentUID: false,
            userID: false,
          },
          "chatBg": {
            currentUID: 0,
            userID: 0,
          },
        });
      } else {
        final data = existing.data() ?? const <String, dynamic>{};
        final existingParticipants = data["participants"] is List
            ? List<String>.from(
                (data["participants"] as List).map((e) => e.toString()),
              )
            : <String>[];
        final hasCanonicalParticipants = existingParticipants.length == 2 &&
            existingParticipants.contains(currentUID) &&
            existingParticipants.contains(userID);
        final unread = _sanitizeUnreadMap(data["unread"], participants);
        unread[currentUID] = 0;
        unread[userID] = (unread[userID] ?? 0) + 1;
        final archived = _sanitizeBoolParticipantMap(
          data["archived"],
          participants,
          defaultValue: false,
        );
        archived[currentUID] = false;
        archived[userID] = false;
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
        await conversationRef.set({
          if (!hasCanonicalParticipants) "participants": participants,
          if (!hasCanonicalParticipants) "userID1": participants.first,
          if (!hasCanonicalParticipants) "userID2": participants.last,
          "lastMessage": "Gönderi",
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

      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatId)
          .collection("messages")
          .add({
        "senderId": currentUID,
        "text": "",
        "createdDate": DateTime.now().millisecondsSinceEpoch,
        "seenBy": [currentUID],
        "type": "post",
        "mediaUrls": [],
        "likes": <String>[],
        "isDeleted": false,
        "isEdited": false,
        "audioUrl": "",
        "postRef": {
          "postId": postID,
          "postType": postType,
          "previewText": "",
          "previewImageUrl": "",
        }
      });

      search.text = "";
      searchFocus.value.unfocus();
      selectedUser.value = null;
      Get.back();
      AppSnackbar("Gönderildi", "Gönderi iletildi");
      chatListingController.getList();
    } catch (e) {
      AppSnackbar("Hata", "Gönderilemedi: $e");
    }
  }

  Future<void> searchUser(String keyword) async {
    if (keyword.trim().isEmpty) {
      followings.clear();
      getFolowers();
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection("users")
        .where("nickname", isGreaterThanOrEqualTo: keyword)
        .where("nickname", isLessThan: '${keyword}z')
        .limit(20)
        .get();

    followings.clear();
    for (var doc in query.docs) {
      followings.add(OgrenciModel.fromMap(doc.id, doc.data()));
    }
  }
}
