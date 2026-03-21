import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class BiographyMakerController extends GetxController {
  static BiographyMakerController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      BiographyMakerController(),
      permanent: permanent,
    );
  }

  static BiographyMakerController? maybeFind() {
    if (!Get.isRegistered<BiographyMakerController>()) return null;
    return Get.find<BiographyMakerController>();
  }

  final bioController = TextEditingController();
  var currentLength = 0.obs;
  var isSaving = false.obs;
  final CurrentUserService userService = CurrentUserService.instance;

  @override
  void onInit() {
    super.onInit();
    final initialBio = userService.currentUser?.bio ?? '';
    bioController.text = initialBio;
    currentLength.value = initialBio.length;
    bioController.addListener(() {
      currentLength.value = bioController.text.length;
    });
  }

  @override
  void onClose() {
    bioController.dispose();
    super.onClose();
  }

  Future<void> setData() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await userService.updateFields({"bio": bioController.text.trim()});
      Get.back();
    } finally {
      isSaving.value = false;
    }
  }
}
