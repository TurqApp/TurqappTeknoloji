import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contact_add/contact.dart';
import 'package:contact_add/contact_add.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/BottomSheets/show_action_sheet.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Models/posts_model.dart';

class MessageContentController extends GetxController {
  final MessageModel model;
  final String mainID;

  var nickname = "".obs;
  var pfImage = "".obs;

  var currentIndex = 0.obs;
  var showAllImages = false.obs;
  RxList<String> imageUrls = <String>[].obs;
  var postModel = Rx<PostsModel?>(null);

  MessageContentController({
    required this.model,
    required this.mainID,
  });

  var postNickname = "".obs;
  var postPfImage = "".obs;

  @override
  void onInit() {
    super.onInit();

    // model.imgs atanır
    imageUrls.assignAll(model.imgs);

    // kullanıcı verisini al
    FirebaseFirestore.instance
        .collection("users")
        .doc(model.userID)
        .get()
        .then((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      nickname.value =
          (data["displayName"] ?? data["username"] ?? data["nickname"] ?? "")
              .toString();
      pfImage.value = (data["avatarUrl"] ??
              data["pfImage"] ??
              data["photoURL"] ??
              data["profileImageUrl"] ??
              "")
          .toString();
    });

    if (model.postID != "") {
      getPost();
    }
  }

  Future<void> showMapsSheet() async {
    Get.bottomSheet(
      barrierColor: Colors.black.withAlpha(50),
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    "Haritalarda Aç",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=${model.lat},${model.long}");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  Get.back();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Image.asset("assets/icons/googlemaps.webp"),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Google Haritalar'da Aç",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (Platform.isIOS)
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(
                        "http://maps.apple.com/?q=${model.lat},${model.long}");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Image.asset("assets/icons/applemaps.webp"),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Apple Haritalar'da Aç",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                      "yandexmaps://maps.yandex.ru/?ll=${model.long},${model.lat}&z=10");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    final webUrl = Uri.parse(
                        "https://yandex.com/maps/?ll=${model.long},${model.lat}&z=10");
                    if (await canLaunchUrl(webUrl)) {
                      await launchUrl(webUrl,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                  Get.back();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Image.asset("assets/icons/yandexmaps.webp"),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Yandex Haritalar'da Aç",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
  }

  Future<void> addContact() async {
    await ContactAdd.addContact(Contact(
        firstname: model.kisiAdSoyad,
        phone: model.kisiTelefon.startsWith("5")
            ? "+90${model.kisiTelefon}"
            : model.kisiTelefon));
  }

  Future<void> showContactInfo() async {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Kişi Bilgisi",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold"),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
              SizedBox(height: 15),
              Text(
                model.kisiAdSoyad,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              Text(
                model.kisiTelefon,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: addContact,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Text(
                          "Rehbere Kaydet",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium"),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse("tel://${model.kisiTelefon}"));
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "Telefon Et",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: "MontserratMedium"),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> deleteMessage() async {
    if (model.source == "preview") return;
    await showActionSheet(
      title: "Mesajı Sil",
      message: "Bu mesajı silmek istediğinizden emin misiniz?",
      titleColor: Colors.black,
      messageColor: Colors.grey.shade600,
      cancelText: "Vazgeç",
      cancelButtonColor: Colors.blueAccent,
      actions: [
        {
          'text': "Sadece Benden Sil",
          'isDestructive': true,
          'color': Colors.red,
          'onPressed': () {
            if (model.source == "conversation") {
              FirebaseFirestore.instance
                  .collection("conversations")
                  .doc(mainID)
                  .collection("messages")
                  .doc(model.rawDocID)
                  .update({
                "isDeleted": true,
              });
            } else {
              FirebaseFirestore.instance
                  .collection("message")
                  .doc(mainID)
                  .collection("Chat")
                  .doc(model.rawDocID)
                  .update({
                "kullanicilar": FieldValue.arrayRemove(
                    [FirebaseAuth.instance.currentUser!.uid])
              });
            }
          },
        },
        {
          'text': "Mesajı Herkesten Sil",
          'isDestructive': false,
          'color': Colors.red,
          'onPressed': () {
            if (model.source == "conversation") {
              FirebaseFirestore.instance
                  .collection("conversations")
                  .doc(mainID)
                  .collection("messages")
                  .doc(model.rawDocID)
                  .update({
                "unsent": true,
                "text": "",
                "mediaUrls": <String>[],
                "isDeleted": false,
              });
            } else {
              FirebaseFirestore.instance
                  .collection("message")
                  .doc(mainID)
                  .collection("Chat")
                  .doc(model.rawDocID)
                  .update({
                "unsent": true,
                "metin": "",
                "imgs": <String>[],
                "lat": 0,
                "long": 0,
                "postID": "",
                "postType": "",
                "kisiAdSoyad": "",
                "kisiTelefon": "",
              });
            }
          },
        },
      ],
    );
  }

  Future<void> likeImage() async {
    final docRef = model.source == "conversation"
        ? FirebaseFirestore.instance
            .collection("conversations")
            .doc(mainID)
            .collection("messages")
            .doc(model.rawDocID)
        : FirebaseFirestore.instance
            .collection("message")
            .doc(mainID)
            .collection("Chat")
            .doc(model.rawDocID);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final fieldName = model.source == "conversation" ? "likes" : "begeniler";
      final currentLikes = List<String>.from(docSnapshot.get(fieldName) ?? []);
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;

      if (currentLikes.contains(currentUserID)) {
        await docRef.update({
          fieldName: FieldValue.arrayRemove([currentUserID])
        });
      } else {
        await docRef.update({
          fieldName: FieldValue.arrayUnion([currentUserID])
        });
      }
    }
  }

  Future<void> deleteSingleImage(String imgUrl) async {
    if (model.source == "preview") return;
    await noYesAlert(
      title: "Fotoğrafı Sil",
      message: "Bu fotoğrafı silmek istediğinizden emin misiniz?",
      cancelText: "İptal",
      yesText: "Fotoğrafı Sil",
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () async {
        await FirebaseFirestore.instance
            .collection(
                model.source == "conversation" ? "conversations" : "message")
            .doc(mainID)
            .collection(model.source == "conversation" ? "messages" : "Chat")
            .doc(model.rawDocID)
            .update(model.source == "conversation"
                ? {
                    "mediaUrls": FieldValue.arrayRemove([imgUrl])
                  }
                : {
                    "imgs": FieldValue.arrayRemove([imgUrl])
                  });
      },
    );
  }

  Future<void> getPost() async {
    FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.postID)
        .get()
        .then((doc) {
      if (doc.exists) {
        postModel.value = PostsModel.fromFirestore(doc);
      } else {
        postModel.value = PostsModel.empty();
      }

      if (postModel.value != null) {
        FirebaseFirestore.instance
            .collection("users")
            .doc(postModel.value!.userID)
            .get()
            .then((doc) {
          final data = doc.data() ?? const <String, dynamic>{};
          postNickname.value = (data["displayName"] ??
                  data["username"] ??
                  data["nickname"] ??
                  "")
              .toString();
          postPfImage.value = (data["avatarUrl"] ??
                  data["pfImage"] ??
                  data["photoURL"] ??
                  data["profileImageUrl"] ??
                  "")
              .toString();
        });
      }
    });
  }
}
