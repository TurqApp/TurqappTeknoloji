import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PoliciesController extends GetxController {
  var privacyPolicy = "".obs;
  var eula = "".obs;
  var ad = "".obs;

  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    FirebaseFirestore.instance
        .collection('Yönetim')
        .doc("Policies")
        .get()
        .then((doc) {
      privacyPolicy.value = doc.get("privacy");
      eula.value = doc.get("eula");
      ad.value = doc.get("ad");
    });
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
