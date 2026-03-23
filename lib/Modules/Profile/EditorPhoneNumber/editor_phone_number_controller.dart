import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/phone_utils.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'editor_phone_number_controller_data_part.dart';
part 'editor_phone_number_controller_actions_part.dart';

class EditorPhoneNumberController extends GetxController {
  static EditorPhoneNumberController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      EditorPhoneNumberController(),
      permanent: permanent,
    );
  }

  static EditorPhoneNumberController? maybeFind() {
    final isRegistered = Get.isRegistered<EditorPhoneNumberController>();
    if (!isRegistered) return null;
    return Get.find<EditorPhoneNumberController>();
  }

  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  final phoneValue = "".obs;
  final codeValue = "".obs;
  final countdown = 0.obs;
  final isCodeSent = false.obs;
  final isBusy = false.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;

  String get _currentUid => _userService.effectiveUserId;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _seedFromCurrentUser();
    unawaited(_loadInitialPhone());

    phoneController.addListener(() {
      phoneValue.value = phoneController.text;
    });

    codeController.addListener(() {
      codeValue.value = codeController.text;
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    super.onClose();
  }

  bool get isPhoneValid {
    final newPhone = phoneDigitsOnly(phoneController.text.trim());
    return newPhone.length == 10 && newPhone.startsWith('5');
  }
}
