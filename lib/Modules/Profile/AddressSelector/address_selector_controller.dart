import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AddressSelectorController extends GetxController {
  static AddressSelectorController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      AddressSelectorController(),
      permanent: permanent,
    );
  }

  static AddressSelectorController? maybeFind() {
    if (!Get.isRegistered<AddressSelectorController>()) return null;
    return Get.find<AddressSelectorController>();
  }

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
    if (current != null && isCurrentUserId(current.userID)) {
      addressController.text = current.adres;
    }

    _userRepository.getUserRaw(CurrentUserService.instance.userId).then((data) {
      addressController.text = ((data ?? const {})["adres"] ?? "").toString();
    });
  }

  @override
  void onClose() {
    addressController.dispose();
    super.onClose();
  }

  Future<void> setData() async {
    await _userRepository.updateUserFields(
      CurrentUserService.instance.userId,
      {"adres": addressController.text},
    );

    Get.back();
  }
}
