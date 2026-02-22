import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:turqappv2/Models/OgrenciModel.dart';
import 'package:uuid/uuid.dart';

import '../../Core/AppSnackbar.dart';
import '../Chat/ChatListing/ChatListingController.dart';

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
        .collection("TakipEdilenler")
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
          String nickname = doc.get("nickname");
          String pfImage = doc.get("pfImage");
          String firstName = doc.get("firstName");
          String lastName = doc.get("lastName");

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
    final userID = selectedUser.value!.userID;
    final sohbet = chatListingController.list.firstWhereOrNull(
      (val) => val.userID == userID,
    );
    if (sohbet != null) {
      sendMessageForStoryNotUse(
          sohbetID: sohbet.chatID, postID: postID, postType: postType);
    } else {
      final newdocid = Uuid().v4();
      FirebaseFirestore.instance.collection("Mesajlar").doc(newdocid).set({
        "deleted": [],
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "userID1": FirebaseAuth.instance.currentUser!.uid,
        "userID2": userID
      }).whenComplete(() {
        sendMessageForStoryNotUse(
            sohbetID: newdocid, postID: postID, postType: postType);
      });
    }
    chatListingController.getList();
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
          .collection("Mesajlar")
          .doc(sohbetID)
          .collection("Chat")
          .add(mesajData)
          .then((_) {
        FirebaseFirestore.instance
            .collection("Mesajlar")
            .doc(sohbetID)
            .update({"timeStamp": DateTime.now().millisecondsSinceEpoch});
      });

      search.text = "";
      searchFocus.value.unfocus();
      Get.back();
      AppSnackbar("Gönderildi",
          "${selectedUser.value!.nickname} kullanıcısına gönderildi");
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
