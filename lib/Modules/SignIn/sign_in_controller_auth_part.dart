part of 'sign_in_controller.dart';

extension SignInControllerAuthPart on SignInController {
  void _finalizeSuccessfulSignInNavigation() {
    wait.value = false;
    _ensureFeedTabSelected();
    Get.offAll(() => NavBarView());
  }

  void _startPostAuthTasks({
    required String email,
    required String password,
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
        () => AccountCenterService.ensure()
            .registerCurrentDeviceSessionIfEnabled(),
      );
      await runStep(
        '_persistStoredSessionCredential',
        () => _persistStoredSessionCredential(
          email: email,
          password: password,
        ),
        timeout: const Duration(seconds: 3),
      );

      try {
        if (Get.isRegistered<UnreadMessagesController>()) {
          final unreadController = Get.find<UnreadMessagesController>();
          unreadController.startListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SignIn] unread listener skipped: $e');
        }
      }
    }());
  }

  Future<bool> signInWithStoredAccount(StoredAccount account) async {
    if (!account.hasPasswordProvider) return false;
    if (account.requiresReauth) return false;
    final credential = await AccountSessionVault.instance.read(account.uid);
    if (credential == null) return false;

    wait.value = true;
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUid.isNotEmpty && currentUid != account.uid) {
        try {
          await _userRepository.updateUserFields(currentUid, {'token': ''});
        } catch (_) {}
        try {
          await CurrentUserService.instance.logout();
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: credential.email,
        password: credential.password,
      );
      final signedUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (signedUid.isNotEmpty) {
        DeviceSessionService.instance.beginSessionClaim(signedUid);
      }
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      _startPostAuthTasks(
        email: credential.email,
        password: credential.password,
      );
      _finalizeSuccessfulSignInNavigation();
      return true;
    } on FirebaseAuthException catch (_) {
      wait.value = false;
      await AccountSessionVault.instance.delete(account.uid);
      await AccountCenterService.ensure().markSessionState(
        uid: account.uid,
        isSessionValid: false,
        requiresReauth: true,
      );
      return false;
    } catch (_) {
      wait.value = false;
      return false;
    }
  }

  Future<void> sendOtpCodeForReset() async {
    if (resetOtpRequestInFlight.value) return;
    final targetEmail = resetMailController.text.trim().toLowerCase();
    if (!isValidEmail(targetEmail)) {
      AppSnackbar("Geçersiz E-posta", "Lütfen geçerli bir e-posta girin.");
      return;
    }
    if (resetCodeRequested.value && otpTimerReset.value > 0) {
      AppSnackbar(
        "Bekleyin",
        "Yeni kod için ${otpTimerReset.value} saniye bekleyin.",
      );
      return;
    }

    wait.value = true;
    resetOtpRequestInFlight.value = true;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('sendPasswordResetSmsCode')
          .call({
        "email": targetEmail,
      });
      startOtpTimerForTimer();
      resetCodeRequested.value = true;
      AppSnackbar(
        "Kod Gönderildi",
        "SMS gönderildi. Kod 60 saniye geçerli.",
      );
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-argument':
          message = "Geçerli bir e-posta ve 6 haneli kod gerekli.";
          break;
        case 'not-found':
          message = "Bu e-posta ile kayıtlı hesap bulunamadı.";
          break;
        case 'failed-precondition':
          final raw = (e.message ?? "").toLowerCase();
          if (raw.contains("yeni sms için")) {
            message =
                "Kod zaten gönderildi. Tekrar göndermek için ${_formatSeconds(otpTimerReset.value)} bekleyin.";
          } else {
            message = e.message ?? "Bu hesap için kayıtlı telefon bulunamadı.";
          }
          break;
        case 'unavailable':
          message = "SMS servisine ulaşılamadı. Lütfen tekrar deneyin.";
          break;
        default:
          message = "Kod gönderilemedi. Lütfen tekrar deneyin.";
      }
      AppSnackbar("Kod Gönderilemedi", message);
    } catch (_) {
      AppSnackbar("Kod Gönderilemedi", "SMS gönderilirken bir hata oluştu.");
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
    final targetEmail = resetMailController.text.trim().toLowerCase();
    final code = resetOtpController.text.trim();

    if (!isValidEmail(targetEmail)) {
      AppSnackbar("Geçersiz E-posta", "Lütfen geçerli bir e-posta girin.");
      return;
    }
    if (code.length != 6 || int.tryParse(code) == null) {
      AppSnackbar("Geçersiz Kod", "Lütfen 6 haneli doğrulama kodunu girin.");
      return;
    }

    wait.value = true;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('verifyPasswordResetSmsCode')
          .call({
        "email": targetEmail,
        "verificationCode": code,
      });
      selection.value = 6;
      resetOtpFocus.value.unfocus();
      resetMailFocus.value.unfocus();
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'deadline-exceeded':
          message = "Kodun süresi doldu (60 sn). Lütfen yeni kod isteyin.";
          break;
        case 'not-found':
          message = "Doğrulama kodu bulunamadı. Yeniden kod alın.";
          break;
        case 'invalid-argument':
          message = "Doğrulama kodu hatalı.";
          break;
        case 'failed-precondition':
          message = e.message ?? "Kod artık geçerli değil. Yeni kod alın.";
          break;
        default:
          message = "Kod doğrulanamadı. Lütfen tekrar deneyin.";
      }
      AppSnackbar("Doğrulama Başarısız", message);
    } catch (_) {
      AppSnackbar(
        "Doğrulama Başarısız",
        "Kod doğrulanırken bir hata oluştu.",
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
      await _restoreAccountIfPendingDeletion();
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
      await AccountCenterService.ensure().registerCurrentDeviceSessionIfEnabled();
      await _persistStoredSessionCredential(
        email: resetMail.value,
        password: newPassword,
      );

      try {
        final storyController = Get.find<StoryRowController>();
        await storyController.loadStories(limit: 100, cacheFirst: false);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
      } catch (_) {}

      late AgendaController agendaController;
      try {
        if (Get.isRegistered<AgendaController>()) {
          agendaController = Get.find<AgendaController>();
        } else {
          agendaController = Get.put(AgendaController());
        }

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
        agendaController = Get.put(AgendaController());
      }

      try {
        if (Get.isRegistered<UnreadMessagesController>()) {
          final unreadController = Get.find<UnreadMessagesController>();
          unreadController.startListeners();
        }
      } catch (_) {}

      wait.value = false;

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}

      _ensureFeedTabSelected();
      Get.offAll(() => const SplashView());
      AppSnackbar(
        "Şifreniz Değiştirildi",
        "Şifreniz başarılı bir şekilde değiştirildi ve giriş yapıldı",
      );
    } on FirebaseAuthException catch (_) {
      AppSnackbar(
        "Bir şeyler ters gitti",
        "Bilinmeyen bir hata oluştu. Hata devam ederse bize ulaşın.",
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
      final signedUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (signedUid.isNotEmpty) {
        DeviceSessionService.instance.beginSessionClaim(signedUid);
      }
      authSucceeded = true;
      try {
        TextInput.finishAutofillContext(shouldSave: true);
      } catch (_) {}
      _startPostAuthTasks(
        email: _resolvedSignInEmail(),
        password: password.value,
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
          message = "E-posta veya şifre hatalı. (${e.code})";
          break;
        case 'invalid-email':
          message = "E-posta formatı geçersiz. (${e.code})";
          break;
        case 'too-many-requests':
          message =
              "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin. (${e.code})";
          break;
        case 'network-request-failed':
          message = "İnternet bağlantısı hatası. (${e.code})";
          break;
        case 'user-disabled':
          message = "Bu kullanıcı hesabı devre dışı bırakılmış. (${e.code})";
          break;
        default:
          message =
              "${e.message ?? 'Giriş sırasında hata oluştu.'} (${e.code})";
      }
      AppSnackbar("Giriş yapılamadı", message);
      return false;
    } catch (_) {
      wait.value = false;
      if (authSucceeded || FirebaseAuth.instance.currentUser != null) {
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}
        _ensureFeedTabSelected();
        Get.offAll(() => NavBarView());
        return true;
      }
      AppSnackbar(
        "Giriş Başarısız",
        "Giriş sırasında beklenmeyen bir hata oluştu. Lütfen tekrar deneyin. (-2)",
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
        final storyController = Get.find<StoryRowController>();
        await Future.any([
          storyController.loadStories(limit: 100, cacheFirst: false),
          Future.delayed(const Duration(seconds: 3)),
        ]);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
      } catch (_) {}

      try {
        final agendaController = Get.isRegistered<AgendaController>()
            ? Get.find<AgendaController>()
            : Get.put(AgendaController());
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
      final search = emailcontroller.text.toLowerCase();
      if (search.length < 2) return;

      if (FirebaseAuth.instance.currentUser == null) {
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
