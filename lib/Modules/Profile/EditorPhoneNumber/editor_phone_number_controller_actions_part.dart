part of 'editor_phone_number_controller.dart';

extension EditorPhoneNumberControllerActionsPart
    on EditorPhoneNumberController {
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
    final email = await resolveAccountEmail();
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
    final email = await resolveAccountEmail();
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

      final ok = result.data is Map && (result.data["success"] == true);
      if (!ok) {
        AppSnackbar('common.error'.tr, 'editor_phone.update_failed'.tr);
        return;
      }

      await ensureAccountCenterService().refreshCurrentAccountMetadata();
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
