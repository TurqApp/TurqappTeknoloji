import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class BiographyMakerController extends GetxController {
  final bioController = TextEditingController();
  var currentLength = 0.obs;
  final CurrentUserService userService = CurrentUserService.instance;

  @override
  void onInit() {
    super.onInit();
    bioController.addListener(() {
      currentLength.value = bioController.text.length;
    });
    bioController.text = userService.currentUser?.bio ?? '';
  }

  @override
  void onClose() {
    bioController.dispose();
    super.onClose();
  }

  Future<void> setData() async {
    await userService.updateFields({"bio": bioController.text});

    Get.back();
  }
}
