import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Models/verified_account_model.dart';

class BecomeVerifiedAccountController extends GetxController {
  final RxString aciklamaText = "".obs;
  var selected = Rx<VerifiedAccountModel?>(null);
  Rx<String> selectedColor = "2196F3".obs;
  var selectedInt = 0.obs;
  var bodySelection = 0.obs;

  final instagram = TextEditingController();
  final twitter = TextEditingController();
  final linkedin = TextEditingController();
  final tiktok = TextEditingController();
  final youtube = TextEditingController();
  final website = TextEditingController();

  final nickname = TextEditingController();
  final aciklama = TextEditingController();

  final eDevletBarcodeNo = TextEditingController();

  var show = false.obs;

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance
        .collection("TurqAppVerified")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      if (doc.exists) {
        bodySelection.value = 3;
      } else {
        selectItem(
            VerifiedAccountModel(title: "Mavi Onay Rozeti", desc: ""), 0);
        aciklama.addListener(() {
          aciklamaText.value = aciklama.text;
        });
      }
    });
  }

  void selectItem(VerifiedAccountModel item, int index) {
    selected.value = item;
    selectedInt.value = index;

    switch (index) {
      case 0:
        selectedColor.value = "2196F3";
        break;
      case 1:
        selectedColor.value = "F44336";
        break;
      case 2:
        selectedColor.value = "FFEB3B";
        break;
      case 3:
        selectedColor.value = "40E0D0";
        break;
      case 4:
        selectedColor.value = "9E9E9E";
        break;
      default:
        selectedColor.value = "000000";
        break;
    }
  }

  void setInstagramDefault() {
    if (instagram.text.isEmpty) instagram.text = "@";
  }

  void setTwitterDefault() {
    if (twitter.text.isEmpty) twitter.text = "@";
  }

  void setLinkedinDefault() {
    if (linkedin.text.isEmpty) linkedin.text = "@";
  }

  void setTiktokDefault() {
    if (tiktok.text.isEmpty) tiktok.text = "@";
  }

  void setYoutubeDefault() {
    if (youtube.text.isEmpty) youtube.text = "@";
  }

  void setWebsiteDefault() {
    if (website.text.isEmpty) website.text = "https://";
  }

  void setNicknameDefault() {
    if (nickname.text.isEmpty) nickname.text = "@";
  }

  void setShowTrue() {
    show.value = true;
  }

  void submitApplication() {
    FirebaseFirestore.instance
        .collection("TurqAppVerified")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      "selected": selected.value?.title,
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
      "aciklama": aciklama.text,
      "website": website.text,
      "instagram": instagram.text,
      "twitter": twitter.text,
      "youtube": youtube.text,
      "linkedin": linkedin.text,
      "tiktok": tiktok.text,
      "talepNickname": nickname.text,
      "eDevletBarCodeNo": eDevletBarcodeNo.text
    });
  }

  @override
  void onClose() {
    instagram.dispose();
    twitter.dispose();
    linkedin.dispose();
    tiktok.dispose();
    youtube.dispose();
    website.dispose();
    nickname.dispose();
    aciklama.dispose();
    eDevletBarcodeNo.dispose();
    super.onClose();
  }
}
