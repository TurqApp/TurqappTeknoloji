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

class EditorPhoneNumberController extends GetxController {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  final phoneValue = "".obs;
  final codeValue = "".obs;
  final countdown = 0.obs;
  final isCodeSent = false.obs;
  final isBusy = false.obs;
  final UserRepository _userRepository = UserRepository.ensure();

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

  void _seedFromCurrentUser() {
    final currentUser = CurrentUserService.instance.currentUser;
    if (currentUser == null) return;
    final phone = currentUser.phoneNumber.trim();
    if (phone.isEmpty) return;
    phoneController.text = phone;
    phoneValue.value = phone;
  }

  Future<void> _loadInitialPhone() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await _userRepository.getUserRaw(uid);
    phoneController.text = (data ?? const {})["phoneNumber"]?.toString() ?? "";
    phoneValue.value = phoneController.text;
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

  Future<String> _resolveAccountEmail() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return "";

    final authEmail = normalizeEmailAddress(current.email);
    if (authEmail.isNotEmpty) return authEmail;

    final currentUserEmail =
        normalizeEmailAddress(CurrentUserService.instance.currentUser?.email);
    if (currentUserEmail.isNotEmpty) return currentUserEmail;

    final data = await _userRepository.getUserRaw(current.uid);
    return normalizeEmailAddress((((data ?? const {})["email"]) ?? "").toString());
  }

  Future<void> sendEmailApproval() async {
    if (isBusy.value) return;
    if (countdown.value > 0) {
      AppSnackbar(
        'common.info'.tr,
        'editor_phone.wait'.trParams({'seconds': '$countdown'}),
      );
      return;
    }
    if (!isPhoneValid) {
      AppSnackbar('common.info'.tr, 'editor_phone.invalid_phone'.tr);
      return;
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      AppSnackbar('common.info'.tr, 'editor_phone.session_missing'.tr);
      return;
    }
    final email = await _resolveAccountEmail();
    if (email.isEmpty) {
      AppSnackbar('common.info'.tr, 'editor_phone.email_missing'.tr);
      return;
    }

    isBusy.value = true;
    try {
      await current.getIdToken(true);
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('sendEmailVerificationCode')
          .call({
        "email": email,
        "purpose": "phone_change",
        "newPhone": phoneController.text.trim(),
        "idToken": await current.getIdToken(),
      });

      isCodeSent.value = true;
      countdown.value = 60;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value > 0) {
          countdown.value--;
        } else {
          timer.cancel();
        }
      });

      AppSnackbar('common.success'.tr, 'editor_phone.code_sent'.tr);
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar(
        'common.info'.tr,
        e.message ?? 'editor_phone.code_send_failed'.tr,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'editor_phone.code_send_failed'.tr);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> confirmAndUpdatePhone() async {
    if (isBusy.value) return;
    if (!isPhoneValid) {
      AppSnackbar('common.info'.tr, 'editor_phone.invalid_phone'.tr);
      return;
    }

    final code = codeController.text.trim();
    if (code.length != 6) {
      AppSnackbar('common.info'.tr, 'editor_phone.enter_code'.tr);
      return;
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      AppSnackbar('common.info'.tr, 'editor_phone.session_missing'.tr);
      return;
    }
    final email = await _resolveAccountEmail();
    if (email.isEmpty) {
      AppSnackbar('common.info'.tr, 'editor_phone.email_missing'.tr);
      return;
    }

    isBusy.value = true;
    try {
      await current.getIdToken(true);
      final idToken = await current.getIdToken();

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('verifyEmailCode')
          .call({
        "email": email,
        "purpose": "phone_change",
        "verificationCode": code,
        "idToken": idToken,
      });

      final result = await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('updateUserPhoneNumberAfterEmailVerification')
          .call({
        "newPhone": phoneController.text.trim(),
        "idToken": idToken,
      });

      final ok = (result.data is Map && (result.data["success"] == true));
      if (!ok) {
        AppSnackbar('common.error'.tr, 'editor_phone.update_failed'.tr);
        return;
      }

      await AccountCenterService.ensure().refreshCurrentAccountMetadata();
      Get.back();
      AppSnackbar('common.success'.tr, 'editor_phone.updated'.tr);
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar(
        'common.info'.tr,
        e.message ?? 'editor_phone.update_failed'.tr,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'editor_phone.update_failed'.tr);
    } finally {
      isBusy.value = false;
    }
  }
}
