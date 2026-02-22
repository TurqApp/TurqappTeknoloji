import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressSelectorController extends GetxController {
  final TextEditingController addressController = TextEditingController();
  final currentLength = 0.obs;

  @override
  void onInit() {
    super.onInit();
    addressController.addListener(() {
      currentLength.value = addressController.text.length;
    });

    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      addressController.text = doc.get("adres");
    });
  }

  Future<void> setData() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({"adres": addressController.text});

    Get.back();
  }
}
