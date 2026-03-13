import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

class PoliciesController extends GetxController {
  var privacyPolicy = "".obs;
  var eula = "".obs;
  var ad = "".obs;

  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);

  @override
  void onInit() {
    super.onInit();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    final doc = await ConfigRepository.ensure().getLegacyConfigDoc(
      collection: 'Yönetim',
      docId: 'Policies',
      preferCache: true,
    );
    if (doc == null) return;
    privacyPolicy.value = (doc["privacy"] ?? "").toString();
    eula.value = (doc["eula"] ?? "").toString();
    ad.value = (doc["ad"] ?? "").toString();
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
