part of 'sign_in_controller.dart';

extension SignInControllerSignupPart on SignInController {
  Future<void> addToFirestore(BuildContext context) async {
    if (wait.value) return;
    closeKeyboard(context);
    wait.value = true;
    var accountProvisioned = false;
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('auth-user-null-after-create');
      }
      final uid = authUser.uid;
      final Map<String, dynamic> userDoc = buildInitialUserDocument(
        firstName: firstName.value,
        lastName: lastName.value,
        nickname: nickname.value,
        email: email.value,
        phoneNumber: phoneNumber.value,
      );
      final userSubdocs = buildInitialUserSubdocuments(userDoc: userDoc);

      try {
        await PhoneAccountLimiter().createUserWithLimit(
          uid: uid,
          phone: phoneNumber.value,
          userData: userDoc,
        );
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          await _userRepository.upsertUserFields(uid, userDoc);
        } else {
          rethrow;
        }
      }

      await _userRepository.upsertUserFields(uid, userDoc);
      final subdocWrites = <Future<void>>[];
      userSubdocs.forEach((path, data) {
        final segments = path.split('/');
        if (segments.length == 2) {
          subdocWrites.add(
            _userSubdocRepository.setDoc(
              uid,
              collection: segments[0],
              docId: segments[1],
              data: Map<String, dynamic>.from(data),
              merge: true,
            ),
          );
        }
      });
      await Future.wait(subdocWrites);
      accountProvisioned = true;

      final createdUserData =
          await _userRepository.getUserRaw(uid, preferCache: false);
      if (createdUserData == null) {
        throw Exception('users-doc-not-created-after-signup');
      }

      await MandatoryFollowService.instance.enforceForCurrentUser();
      accountProvisioned = true;

      try {
        await CurrentUserService.instance.initialize();
        await NotificationService.instance.initialize();
        await _clearSessionCachesAfterAccountSwitch();
        await CurrentUserService.instance.forceRefresh();
      } catch (_) {}

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

      _ensureFeedTabSelected();
      Get.off(() => NavBarView());
    } on PhoneAccountLimitReached catch (e) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      AppSnackbar(
        'Limit Aşıldı',
        e.message.isNotEmpty
            ? e.message
            : 'Bu telefon numarası için en fazla 5 hesap oluşturulabilir.',
      );
      wait.value = false;
    } on UsernameAlreadyTaken catch (e) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      AppSnackbar(
        'Kullanıcı adı kullanımda',
        e.message.isNotEmpty
            ? e.message
            : 'Lütfen farklı bir kullanıcı adı seç.',
      );
      wait.value = false;
    } catch (_) {
      wait.value = false;
      if (accountProvisioned) {
        _ensureFeedTabSelected();
        Get.off(() => NavBarView());
        return;
      }
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}
      AppSnackbar(
        'Kayıt tamamlanamadı',
        'Hesap oluşturma sırasında bir hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  Future<void> searchEmail() async {
    final candidate = emailcontroller.text.trim().toLowerCase();
    final requestId = ++_emailAvailabilityRequestId;
    emailAvilable.value = false;
    if (!isValidEmail(candidate)) return;

    final result = await _checkSignupAvailabilityHttp(email: candidate);
    if (requestId != _emailAvailabilityRequestId) return;
    emailAvilable.value = result.emailAvailable;
  }

  bool isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    final emailRegex =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> verifyPassword() async {
    final pasword = password.value.toString();
    final containsLetter = RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ]').hasMatch(pasword);
    final containsNumber = RegExp(r'[0-9]').hasMatch(pasword);
    final containsPunct =
        RegExp(r'[!@#\$%\^&*()_+\-=\[\]{};:\\|,.<>\/?~]').hasMatch(pasword);
    final minLen = pasword.length >= 6;

    passwordAvilable.value =
        containsLetter && containsNumber && containsPunct && minLen;
  }

  Future<void> searchNickname() async {
    final usernameLower = nickname.value.trim().toLowerCase();
    final requestId = ++_nicknameAvailabilityRequestId;
    nicknameAvilable.value = false;
    if (usernameLower.length < 8) return;

    final result = await _checkSignupAvailabilityHttp(nickname: usernameLower);
    if (requestId != _nicknameAvailabilityRequestId) return;
    nicknameAvilable.value = result.nicknameAvailable;
  }

  void scheduleEmailAvailabilityCheck() {
    _emailAvailabilityDebounce?.cancel();
    _emailAvailabilityDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        unawaited(searchEmail());
      },
    );
  }

  void scheduleNicknameAvailabilityCheck() {
    _nicknameAvailabilityDebounce?.cancel();
    _nicknameAvailabilityDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        unawaited(searchNickname());
      },
    );
  }

  Future<bool> validateSignupIdentityStep() async {
    if (signupIdentityCheckLoading.value) return false;
    signupIdentityCheckLoading.value = true;
    final emailText = emailcontroller.text.trim().toLowerCase();
    final nicknameText = nicknamecontroller.text.trim().toLowerCase();
    final pass = passwordcontroller.text;

    try {
      if (!isValidEmail(emailText)) {
        AppSnackbar('Eksik Bilgi', 'Lütfen geçerli bir e-posta girin.');
        return false;
      }
      if (nicknameText.length < 8) {
        AppSnackbar('Eksik Bilgi', 'Kullanıcı adı en az 8 karakter olmalı.');
        return false;
      }

      password.value = pass;
      await verifyPassword();
      if (!passwordAvilable.value) {
        AppSnackbar(
          'Zayıf Şifre',
          'Şifre en az bir harf, bir sayı ve bir noktalama içermeli (min 6 karakter).',
        );
        return false;
      }

      final availability = await _checkSignupAvailabilityHttp(
        email: emailText,
        nickname: nicknameText,
        showServiceError: true,
      );
      emailAvilable.value = availability.emailAvailable;
      nicknameAvilable.value = availability.nicknameAvailable;
      if (!availability.reachable) return false;
      if (!availability.emailAvailable) {
        AppSnackbar('Kullanılamaz', 'Bu e-posta zaten kullanımda.');
        return false;
      }
      if (!availability.nicknameAvailable) {
        AppSnackbar('Kullanılamaz', 'Bu kullanıcı adı zaten kullanımda.');
        return false;
      }
      return true;
    } finally {
      signupIdentityCheckLoading.value = false;
    }
  }

  Future<
      ({
        bool emailAvailable,
        bool nicknameAvailable,
        bool reachable,
      })> _checkSignupAvailabilityHttp({
    String? email,
    String? nickname,
    bool showServiceError = false,
  }) async {
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    final normalizedNickname = (nickname ?? '').trim().toLowerCase();

    try {
      final response = await _dio.post(
        SignInController._signupAvailabilityUrl,
        data: {
          if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
          if (normalizedNickname.isNotEmpty) 'nickname': normalizedNickname,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return (
        emailAvailable: data['emailAvailable'] == true,
        nicknameAvailable: data['nicknameAvailable'] == true,
        reachable: true,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return (
          emailAvailable: responseData['emailAvailable'] == true,
          nicknameAvailable: responseData['nicknameAvailable'] == true,
          reachable: e.response?.statusCode == 400,
        );
      }
      if (showServiceError) {
        AppSnackbar(
          'Kontrol Edilemedi',
          'Kayıt uygunluğu şu anda kontrol edilemiyor. Lütfen tekrar deneyin.',
        );
      }
      return (
        emailAvailable: false,
        nicknameAvailable: false,
        reachable: false,
      );
    } catch (_) {
      if (showServiceError) {
        AppSnackbar(
          'Kontrol Edilemedi',
          'Kayıt uygunluğu şu anda kontrol edilemiyor. Lütfen tekrar deneyin.',
        );
      }
      return (
        emailAvailable: false,
        nicknameAvailable: false,
        reachable: false,
      );
    }
  }

  Future<void> sendOtpCode() async {
    _logSignupOtp('start', {
      'selection': selection.value,
      'phoneLength': phoneNumber.value.trim().length,
      'hasEmail': email.value.trim().isNotEmpty,
      'hasNickname': nickname.value.trim().isNotEmpty,
      'timer': otpTimer.value,
      'inFlight': otpRequestInFlight.value,
    });
    if (otpRequestInFlight.value) {
      _logSignupOtp('blocked_in_flight');
      return;
    }
    if (signupCodeRequested.value && otpTimer.value > 0) {
      _logSignupOtp('blocked_timer', {
        'remainingSec': otpTimer.value,
      });
      AppSnackbar(
        "Bekleyin",
        "Yeni kod için ${otpTimer.value} saniye bekleyin.",
      );
      return;
    }

    final phone = phoneNumber.value.trim();
    if (phone.length != 10 || !phone.startsWith('5')) {
      _logSignupOtp('invalid_phone', {
        'phone': phone,
      });
      AppSnackbar(
        "Geçersiz Telefon",
        "Lütfen 5 ile başlayan 10 haneli telefon numarası girin.",
      );
      return;
    }

    otpRequestInFlight.value = true;
    try {
      final payload = {
        "phone": phone,
        "email": email.value.trim().toLowerCase(),
        "nickname": nickname.value.trim().toLowerCase(),
      };
      _logSignupOtp('callable_request', {
        'phone': phone,
        'email': payload['email'],
        'nickname': payload['nickname'],
      });
      final result =
          await _functions.httpsCallable('sendSignupSmsCode').call(payload);
      _logSignupOtp('callable_success', {
        'data': result.data,
      });
      selection.value = 4;
      startOtpTimer();
      signupCodeRequested.value = true;
      _logSignupOtp('ui_advanced_to_otp', {
        'selection': selection.value,
      });
      AppSnackbar(
        "Kod Gönderildi",
        "SMS gönderildi. Kod 120 saniye geçerli.",
      );
    } on FirebaseFunctionsException catch (e) {
      _logSignupOtp('callable_error', {
        'code': e.code,
        'message': e.message,
        'details': e.details,
      });
      String message;
      switch (e.code) {
        case 'invalid-argument':
          message = e.message ?? "Girilen bilgiler geçerli değil.";
          break;
        case 'already-exists':
          message = e.message ?? "Bu bilgiler zaten kullanımda.";
          break;
        case 'failed-precondition':
          message = e.message ?? "Yeni kod istemeden önce biraz bekleyin.";
          break;
        case 'unavailable':
          message = "SMS servisine ulaşılamadı. Lütfen tekrar deneyin.";
          break;
        default:
          message = "Kod gönderilemedi. Lütfen tekrar deneyin.";
      }
      AppSnackbar("Kod Gönderilemedi", message);
    } catch (e, st) {
      _logSignupOtp('unexpected_error', {
        'error': e.toString(),
        'stack': st.toString().split('\n').take(3).join(' | '),
      });
      AppSnackbar("Kod Gönderilemedi", "SMS gönderilirken bir hata oluştu.");
    } finally {
      _logSignupOtp('finish', {
        'selection': selection.value,
        'codeRequested': signupCodeRequested.value,
      });
      otpRequestInFlight.value = false;
    }
  }

  void startOtpTimer() {
    _timer?.cancel();
    otpTimer.value = 120;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimer.value > 0) {
        otpTimer.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> verifySignupOtpAndCreateAccount(BuildContext context) async {
    if (wait.value) return;
    final phone = phoneNumber.value.trim();
    final code = otpCode.value.trim();

    if (phone.length != 10 || !phone.startsWith('5')) {
      AppSnackbar(
        "Geçersiz Telefon",
        "Lütfen 5 ile başlayan 10 haneli telefon numarası girin.",
      );
      return;
    }
    if (code.length != 6 || int.tryParse(code) == null) {
      AppSnackbar(
        "Geçersiz Kod",
        "Lütfen 6 haneli doğrulama kodunu girin.",
      );
      return;
    }

    wait.value = true;
    try {
      await _functions.httpsCallable('verifySignupSmsCode').call({
        "phone": phone,
        "verificationCode": code,
        "email": email.value.trim().toLowerCase(),
        "nickname": nickname.value.trim().toLowerCase(),
      });

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: password.value.trim(),
      );
      addToFirestore(context);
    } on FirebaseFunctionsException catch (e) {
      wait.value = false;
      String message;
      switch (e.code) {
        case 'deadline-exceeded':
          message = "Kodun süresi doldu. Lütfen yeni kod isteyin.";
          break;
        case 'already-exists':
          message =
              e.message ?? "Bu e-posta veya kullanıcı adı zaten kullanımda.";
          break;
        case 'not-found':
          message = "Doğrulama kodu bulunamadı. Yeniden kod alın.";
          break;
        case 'invalid-argument':
          message = "Doğrulama kodu hatalı.";
          break;
        case 'resource-exhausted':
          message = "Çok fazla hatalı deneme yapıldı. Yeni kod isteyin.";
          break;
        case 'failed-precondition':
          message = e.message ?? "Kod artık geçerli değil. Yeni kod alın.";
          break;
        default:
          message = "Kod doğrulanamadı. Lütfen tekrar deneyin.";
      }
      AppSnackbar("Doğrulama Başarısız", message);
    } on FirebaseAuthException catch (e) {
      wait.value = false;
      final code = e.code;
      String message;
      switch (code) {
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kullanımda.';
          break;
        case 'invalid-email':
          message = 'E-posta adresi geçersiz.';
          break;
        case 'weak-password':
          message = 'Şifre çok zayıf. Daha güçlü bir şifre deneyin.';
          break;
        case 'operation-not-allowed':
          message = 'E-posta/şifre kayıt yöntemi kapalı.';
          break;
        case 'network-request-failed':
          message = 'İnternet bağlantısı kurulamadı.';
          break;
        default:
          message = '${e.message ?? 'Kayıt işlemi başarısız.'} ($code)';
      }
      AppSnackbar('Hesap oluşturulamadı', message);
    } catch (_) {
      wait.value = false;
      AppSnackbar(
        'Hesap oluşturulamadı',
        'Kayıt sırasında beklenmeyen bir hata oluştu.',
      );
    }
  }
}
