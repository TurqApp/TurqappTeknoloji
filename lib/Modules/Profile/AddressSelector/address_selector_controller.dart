import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AddressSelectorController extends GetxController {
  final TextEditingController addressController = TextEditingController();
  final currentLength = 0.obs;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    addressController.addListener(() {
      currentLength.value = addressController.text.length;
    });

    final current = CurrentUserService.instance.currentUser;
    if (current != null &&
        current.userID == FirebaseAuth.instance.currentUser?.uid) {
      addressController.text = current.adres;
    }

    _userRepository
        .getUserRaw(FirebaseAuth.instance.currentUser!.uid)
        .then((data) {
      addressController.text = ((data ?? const {})["adres"] ?? "").toString();
    });
  }

  Future<void> setData() async {
    await _userRepository.updateUserFields(
      FirebaseAuth.instance.currentUser!.uid,
      {"adres": addressController.text},
    );

    Get.back();
  }
}
