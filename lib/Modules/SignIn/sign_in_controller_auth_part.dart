part of 'sign_in_controller.dart';

extension SignInControllerAuthPart on SignInController {
  void _finalizeSuccessfulSignInNavigation() {
    wait.value = false;
    _ensureFeedTabSelected();
    Get.offAll(() => NavBarView());
  }

  void _startPostAuthTasks({
    required String email,
  }) {
    unawaited(() async {
      Future<void> runStep(
        String label,
        Future<void> Function() action, {
        Duration timeout = const Duration(seconds: 6),
      }) async {
        try {
          await action().timeout(timeout);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[SignIn] post-auth step skipped ($label): $e');
          }
        }
      }

      await runStep(
        'refreshEmailVerificationStatus',
        () => CurrentUserService.instance.refreshEmailVerificationStatus(
          reloadAuthUser: true,
        ),
      );
      unawaited(MandatoryFollowService.instance.enforceForCurrentUser());
      unawaited(_postLoginWarmup());
      await runStep(
          '_trackCurrentAccountForDevice', _trackCurrentAccountForDevice);
      await runStep(
        'registerCurrentDeviceSessionIfEnabled',
        () => ensureAccountCenterService()
            .registerCurrentDeviceSessionIfEnabled(),
      );
      await runStep(
        '_persistStoredSessionHint',
        () => _persistStoredSessionHint(
          email: email,
        ),
        timeout: const Duration(seconds: 3),
      );

      try {
        maybeFindUnreadMessagesController()?.startListeners();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SignIn] unread listener skipped: $e');
        }
      }
    }());
  }

  Future<bool> signInWithStoredAccount(StoredAccount account) async {
    if (!account.hasPasswordProvider) return false;
    await ensureAccountCenterService().markSessionState(
      uid: account.uid,
      isSessionValid: false,
      requiresReauth: requiresManualStoredAccountReauth(account),
    );
    return false;
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
        DeviceSessionService.instance.beginSessionClaim(signedUid);
      }
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      await MandatoryFollowService.instance.enforceForCurrentUser();

      await userCredential.user!.updatePassword(newPassword);
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}

      await CurrentUserService.instance.initialize();
      await NotificationService.instance.initialize();
      await _clearSessionCachesAfterAccountSwitch();
      await CurrentUserService.instance.forceRefresh();
      await _trackCurrentAccountForDevice();
      await ensureAccountCenterService()
          .registerCurrentDeviceSessionIfEnabled();
      await _persistStoredSessionHint(
        email: resetMail.value,
      );

      try {
        final storyController = maybeFindStoryRowController();
        if (storyController == null) return;
        await storyController.loadStories(limit: 100, cacheFirst: false);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
      } catch (_) {}

      late AgendaController agendaController;
      try {
        agendaController = ensureAgendaController();

        await agendaController.refreshAgenda();

        int retries = 0;
        while (agendaController.agendaList.isEmpty && retries < 3) {
          await agendaController.fetchAgendaBigData(initial: true);
          if (agendaController.agendaList.isEmpty && retries < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          retries++;
        }
      } catch (_) {
        agendaController = ensureAgendaController();
      }

      try {
        maybeFindUnreadMessagesController()?.startListeners();
      } catch (_) {}

      wait.value = false;

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}

      _ensureFeedTabSelected();
      Get.offAll(() => const SplashView());
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
    bool authSucceeded = false;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _resolvedSignInEmail(),
        password: password.value,
      );
      final signedUid = CurrentUserService.instance.authUserId;
      if (signedUid.isNotEmpty) {
        DeviceSessionService.instance.beginSessionClaim(signedUid);
        try {
          await ensureAccountCenterService()
              .registerCurrentDeviceSessionIfEnabled();
        } catch (_) {}
      }
      authSucceeded = true;
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      _startPostAuthTasks(
        email: _resolvedSignInEmail(),
      );
      _finalizeSuccessfulSignInNavigation();
      return true;
    } on FirebaseAuthException catch (e) {
      wait.value = false;
      String message;
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = "${'sign_in.auth_invalid_credential'.tr} (${e.code})";
          break;
        case 'invalid-email':
          message = "${'sign_in.auth_invalid_email'.tr} (${e.code})";
          break;
        case 'too-many-requests':
          message = "${'sign_in.auth_too_many_requests'.tr} (${e.code})";
          break;
        case 'network-request-failed':
          message = "${'sign_in.auth_network_failed'.tr} (${e.code})";
          break;
        case 'user-disabled':
          message = "${'sign_in.auth_user_disabled'.tr} (${e.code})";
          break;
        default:
          message =
              "${e.message ?? 'sign_in.auth_generic_error'.tr} (${e.code})";
      }
      AppSnackbar('sign_in.sign_in_failed_title'.tr, message);
      return false;
    } catch (_) {
      wait.value = false;
      if (authSucceeded || CurrentUserService.instance.hasAuthUser) {
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}
        _ensureFeedTabSelected();
        Get.offAll(() => NavBarView());
        return true;
      }
      AppSnackbar(
        'sign_in.sign_in_failed_title'.tr,
        'sign_in.sign_in_failed_body'.tr,
      );
      return false;
    }
  }

  Future<void> _postLoginWarmup() async {
    try {
      await Future.any([
        CurrentUserService.instance.initialize(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      unawaited(NotificationService.instance.initialize());
      unawaited(_clearSessionCachesAfterAccountSwitch());
      unawaited(CurrentUserService.instance.forceRefresh());

      try {
        final storyController = maybeFindStoryRowController();
        if (storyController == null) return;
        await Future.any([
          storyController.loadStories(limit: 100, cacheFirst: false),
          Future.delayed(const Duration(seconds: 3)),
        ]);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
      } catch (_) {}

      try {
        final agendaController =
            maybeFindAgendaController() ?? ensureAgendaController();
        await Future.any([
          agendaController.refreshAgenda(),
          Future.delayed(const Duration(seconds: 3)),
        ]);
        if (agendaController.agendaList.isEmpty) {
          unawaited(agendaController.fetchAgendaBigData(initial: true));
        }
      } catch (_) {}
    } catch (_) {}
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
