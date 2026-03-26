part of 'editor_email_controller.dart';

extension _EditorEmailControllerRuntimeX on EditorEmailController {
  void seedFromCurrentSources() {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUser = _userService.currentUser;
    final seededEmail = currentUser?.email.trim().isNotEmpty == true
        ? currentUser!.email.trim()
        : (authUser?.email ?? '').trim();
    if (seededEmail.isNotEmpty) {
      emailController.text = seededEmail;
    }
    isEmailConfirmed.value = (currentUser?.email.isNotEmpty == true &&
            _userService.isEmailVerified) ||
        authUser?.emailVerified == true;
  }

  Future<void> fetchAndSetUserData() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final data = await _userRepository.getUserRaw(
      uid,
      preferCache: true,
      cacheOnly: true,
    );
    if (data == null) return;
    final rawEmail = data['email']?.toString().trim() ?? '';
    if (rawEmail.isNotEmpty) {
      emailController.text = rawEmail;
    }
    final firestoreVerified = data['emailVerified'] == true;
    final authVerified =
        FirebaseAuth.instance.currentUser?.emailVerified == true;
    isEmailConfirmed.value = firestoreVerified || authVerified;
  }

  Future<void> sendEmailCode() async {
    if (isBusy.value) return;
    if (countdown.value > 0) {
      AppSnackbar(
        'common.info'.tr,
        'editor_email.wait'.trParams({'seconds': '$countdown'}),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = normalizeEmailAddress(emailController.text);
    if (user == null) {
      AppSnackbar('common.info'.tr, 'editor_email.session_missing'.tr);
      return;
    }
    if (email.isEmpty) {
      AppSnackbar('common.info'.tr, 'editor_email.email_missing'.tr);
      return;
    }
    isBusy.value = true;
    try {
      await user.getIdToken(true);
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('sendEmailVerificationCode')
          .call({
        'email': email,
        'purpose': 'email_confirm',
        'idToken': await user.getIdToken(),
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

      AppSnackbar('common.success'.tr, 'editor_email.code_sent'.tr);
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar(
        'common.info'.tr,
        e.message ?? 'editor_email.code_send_failed'.tr,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'editor_email.code_send_failed'.tr);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> verifyAndConfirmEmail() async {
    if (isBusy.value) return;

    final user = FirebaseAuth.instance.currentUser;
    final email = normalizeEmailAddress(emailController.text);
    final code = codeController.text.trim();

    if (user == null) {
      AppSnackbar('common.info'.tr, 'editor_email.session_missing'.tr);
      return;
    }
    if (email.isEmpty) {
      AppSnackbar('common.info'.tr, 'editor_email.email_missing'.tr);
      return;
    }
    if (code.length != 6) {
      AppSnackbar('common.info'.tr, 'editor_email.enter_code'.tr);
      return;
    }

    isBusy.value = true;
    try {
      await user.getIdToken(true);
      final idToken = await user.getIdToken();

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('verifyEmailCode')
          .call({
        'email': email,
        'purpose': 'email_confirm',
        'verificationCode': code,
        'idToken': idToken,
      });

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('markCurrentEmailVerified')
          .call({'idToken': idToken});

      await FirebaseAuth.instance.currentUser?.reload();
      await _userService.refreshEmailVerificationStatus(
        reloadAuthUser: true,
      );
      await ensureAccountCenterService().refreshCurrentAccountMetadata();
      isEmailConfirmed.value = true;

      Get.back();
      AppSnackbar('common.success'.tr, 'editor_email.verified'.tr);
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar(
        'common.info'.tr,
        e.message ?? 'editor_email.verify_failed'.tr,
      );
    } catch (_) {
      AppSnackbar('common.error'.tr, 'editor_email.verify_failed'.tr);
    } finally {
      isBusy.value = false;
    }
  }
}
