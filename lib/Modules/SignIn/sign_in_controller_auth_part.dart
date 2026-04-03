part of 'sign_in_controller.dart';

extension SignInControllerAuthPart on SignInController {
  void _finalizeSuccessfulSignInNavigation() {
    wait.value = false;
    _ensureFeedTabSelected();
    unawaited(AppRootNavigationService.offAllToAuthenticatedHome());
  }

  Future<bool> signInWithStoredAccount(StoredAccount account) async {
    return _signInApplicationService.signInWithStoredAccount(account);
  }

  Future<void> sendOtpCodeForReset() async {
    if (resetOtpRequestInFlight.value) return;
    final targetEmail = normalizeEmailAddress(resetMailController.text);
    if (!isValidEmail(targetEmail)) {
      AppSnackbar('signup.phone_invalid_title'.tr, 'signup.invalid_email'.tr);
      return;
    }
    if (resetCodeRequested.value && otpTimerReset.value > 0) {
      AppSnackbar(
        'common.info'.tr,
        'editor_email.wait'.trParams({'seconds': '${otpTimerReset.value}'}),
      );
      return;
    }

    wait.value = true;
    resetOtpRequestInFlight.value = true;
    try {
      await _remoteService.sendPasswordResetSmsCode(email: targetEmail);
      startOtpTimerForTimer();
      resetCodeRequested.value = true;
      AppSnackbar(
        'common.success'.tr,
        'sign_in.reset_code_sent'.tr,
      );
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-argument':
          message = 'sign_in.reset_invalid_email_or_code'.tr;
          break;
        case 'not-found':
          message = 'sign_in.reset_account_not_found'.tr;
          break;
        case 'failed-precondition':
          final raw = normalizeLowercase(e.message ?? "");
          if (raw.contains("yeni sms için")) {
            message = 'sign_in.reset_code_already_sent'.trParams(
              {'time': _formatSeconds(otpTimerReset.value)},
            );
          } else {
            message = e.message ?? 'sign_in.reset_phone_missing'.tr;
          }
          break;
        case 'unavailable':
          message = 'signup.sms_unavailable'.tr;
          break;
        default:
          message = 'signup.code_send_failed'.tr;
      }
      AppSnackbar('sign_in.code_send_failed_title'.tr, message);
    } catch (_) {
      AppSnackbar(
          'sign_in.code_send_failed_title'.tr, 'sign_in.sms_send_failed'.tr);
    } finally {
      wait.value = false;
      resetOtpRequestInFlight.value = false;
    }
  }

  void startOtpTimerForTimer() {
    _timerReset?.cancel();
    otpTimerReset.value = 300;

    _timerReset = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimerReset.value > 0) {
        otpTimerReset.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> getResetUserData(String email, String nickname) async {
    resetPhoneNumber.value = "";
    resetUserID.value = "";
    try {
      final emailUser = await _userRepository.findUserByEmail(
        email,
        preferCache: true,
      );

      if (emailUser != null) {
        resetPhoneNumber.value = (emailUser["phoneNumber"] ?? "").toString();
        resetUserID.value = (emailUser["id"] ?? "").toString();
        return;
      }

      final nickUser = await _userRepository.findUserByNickname(
        nickname,
        preferCache: true,
      );

      if (nickUser != null) {
        resetPhoneNumber.value = (nickUser["phoneNumber"] ?? "").toString();
        resetUserID.value = (nickUser["id"] ?? "").toString();
      }
    } catch (_) {}
  }

  Future<void> sendPasswordResetLink() async {
    await sendOtpCodeForReset();
  }

  Future<void> verifyResetSmsCode() async {
    final targetEmail = normalizeEmailAddress(resetMailController.text);
    final code = resetOtpController.text.trim();

    if (!isValidEmail(targetEmail)) {
      AppSnackbar('signup.phone_invalid_title'.tr, 'signup.invalid_email'.tr);
      return;
    }
    if (code.length != 6 || int.tryParse(code) == null) {
      AppSnackbar(
          'signup.code_invalid_title'.tr, 'signup.code_invalid_body'.tr);
      return;
    }

    wait.value = true;
    try {
      await _remoteService.verifyPasswordResetSmsCode(
        email: targetEmail,
        verificationCode: code,
      );
      selection.value = 6;
      resetOtpFocus.value.unfocus();
      resetMailFocus.value.unfocus();
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'deadline-exceeded':
          message = 'sign_in.reset_code_expired'.tr;
          break;
        case 'not-found':
          message = 'signup.code_not_found'.tr;
          break;
        case 'invalid-argument':
          message = 'signup.code_wrong'.tr;
          break;
        case 'failed-precondition':
          message = e.message ?? 'signup.code_no_longer_valid'.tr;
          break;
        default:
          message = 'signup.verify_retry'.tr;
      }
      AppSnackbar('signup.verify_failed_title'.tr, message);
    } catch (_) {
      AppSnackbar(
        'signup.verify_failed_title'.tr,
        'sign_in.verify_code_failed'.tr,
      );
    } finally {
      wait.value = false;
    }
  }

  Future<void> setNewPassword(String newPassword) async {
    wait.value = true;
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resetMail.value,
        password: newPassword,
      );
      final signedUid = userCredential.user?.uid ?? '';
      if (signedUid.isNotEmpty) {
        _deviceSessionRuntimeService.beginSessionClaim(signedUid);
      }
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      await MandatoryFollowService.instance.enforceForCurrentUser();

      await userCredential.user!.updatePassword(newPassword);
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}

      await _signInApplicationService.runForegroundPostAuthBootstrap(
        email: resetMail.value,
        expectedUid: signedUid,
        registerCurrentDeviceSession: true,
      );

      wait.value = false;

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}

      _ensureFeedTabSelected();
      await AppRootNavigationService.offAllToSplash();
      AppSnackbar(
        'sign_in.password_changed_title'.tr,
        'sign_in.password_changed_body'.tr,
      );
    } on FirebaseAuthException catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'sign_in.unknown_error_contact'.tr,
      );
    } catch (_) {}
  }

  Future<bool> signIn() async {
    final result = await _signInApplicationService.signInWithPassword(
      email: _resolvedSignInEmail(),
      password: password.value,
    );
    if (result.isSuccess) {
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      _finalizeSuccessfulSignInNavigation();
      return true;
    }

    wait.value = false;
    final failureCode = result.failureCode;
    if (failureCode != null) {
      String message;
      switch (failureCode) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = "${'sign_in.auth_invalid_credential'.tr} ($failureCode)";
          break;
        case 'invalid-email':
          message = "${'sign_in.auth_invalid_email'.tr} ($failureCode)";
          break;
        case 'too-many-requests':
          message = "${'sign_in.auth_too_many_requests'.tr} ($failureCode)";
          break;
        case 'network-request-failed':
          message = "${'sign_in.auth_network_failed'.tr} ($failureCode)";
          break;
        case 'user-disabled':
          message = "${'sign_in.auth_user_disabled'.tr} ($failureCode)";
          break;
        default:
          message =
              "${result.failureMessage ?? 'sign_in.auth_generic_error'.tr} "
              "($failureCode)";
      }
      AppSnackbar('sign_in.sign_in_failed_title'.tr, message);
      return false;
    }

    AppSnackbar(
      'sign_in.sign_in_failed_title'.tr,
      'sign_in.sign_in_failed_body'.tr,
    );
    return false;
  }

  Future<void> nicknameFinder() async {
    try {
      final search = normalizeEmailAddress(emailcontroller.text);
      if (search.length < 2) return;

      if (!CurrentUserService.instance.hasAuthUser) {
        signInEmail.value = search.contains("@") ? search : "";
        return;
      }

      final found = await _userRepository.findFirstByNicknamePrefix(
        search,
        preferCache: true,
      );

      if (found != null) {
        final email = (found["email"] ?? "").toString();
        signInEmail.value = email;
      } else {
        signInEmail.value = "";
      }
    } catch (_) {}
  }
}
