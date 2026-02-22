import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';

class BiographyMakerController extends GetxController {
  final bioController = TextEditingController();
  var currentLength = 0.obs;

  @override
  void onInit() {
    super.onInit();
    bioController.addListener(() {
      currentLength.value = bioController.text.length;
    });
    final user = Get.find<FirebaseMyStore>();
    bioController.text = user.bio.value;
  }

  @override
  void onClose() {
    bioController.dispose();
    super.onClose();
  }

  Future<void> setData() async {
    FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).update(
        {
          "bio" : bioController.text
        });

    Get.back();
  }
}
