import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
          final pfImage =
              (data["pfImage"] ?? data["photoUrl"] ?? "").toString();
          final firstName = (data["firstName"] ?? "").toString();
          final lastName = (data["lastName"] ?? "").toString();

          followings.add(OgrenciModel(
              userID: item.id,
              firstName: firstName,
              pfImage: pfImage,
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
      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(chatId)
          .set({
        "participants": [currentUID, userID],
        "lastMessage": "Gönderi",
        "lastMessageAt": DateTime.now().millisecondsSinceEpoch,
        "lastSenderId": currentUID,
        "unread.$currentUID": 0,
        "unread.$userID": FieldValue.increment(1),
      }, SetOptions(merge: true));

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

      if (sohbet != null) {
        sendMessageForStoryNotUse(
            sohbetID: sohbet.chatID, postID: postID, postType: postType);
      } else {
        await FirebaseFirestore.instance.collection("message").doc(chatId).set({
          "deleted": [],
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
          "userID1": FirebaseAuth.instance.currentUser!.uid,
          "userID2": userID
        }, SetOptions(merge: true));
        sendMessageForStoryNotUse(
            sohbetID: chatId, postID: postID, postType: postType);
      }
      chatListingController.getList();
    } catch (e) {
      AppSnackbar("Hata", "Gönderilemedi: $e");
    }
  }

  void sendMessageForStoryNotUse({
    List<String>? imageUrls,
    LatLng? latLng,
    String? kisiAdSoyad,
    String? kisiTelefon,
    String? gif,
    String? postID,
    String? postType,
    required String sohbetID,
  }) {
    if (imageUrls != [] ||
        latLng != null ||
        kisiAdSoyad != "" ||
        postID != "") {
      Map<String, dynamic> mesajData = {
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "userID": FirebaseAuth.instance.currentUser!.uid,
        "lat": latLng != null ? latLng.latitude.toDouble() : 0.0,
        "long": latLng != null ? latLng.longitude.toDouble() : 0.0,
        "postType": (postType != "" && postType != null) ? postType : "",
        "postID": (postID != "" && postID != null) ? postID : "",
        "imgs": gif != null ? [gif] : imageUrls ?? [],
        "video": "",
        "isRead": false,
        "kullanicilar": [
          selectedUser.value!.userID,
          FirebaseAuth.instance.currentUser!.uid
        ],
        "metin": "",
        "sesliMesaj": "",
        "kisiAdSoyad": kisiAdSoyad ?? "",
        "kisiTelefon": kisiTelefon ?? "",
        "begeniler": []
      };

      FirebaseFirestore.instance
          .collection("message")
          .doc(sohbetID)
          .collection("Chat")
          .add(mesajData)
          .then((_) {
        FirebaseFirestore.instance
            .collection("message")
            .doc(sohbetID)
            .update({"timeStamp": DateTime.now().millisecondsSinceEpoch});
      });

      search.text = "";
      searchFocus.value.unfocus();
      selectedUser.value = null;
      Get.back();
      AppSnackbar("Gönderildi", "Gönderi iletildi");
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
