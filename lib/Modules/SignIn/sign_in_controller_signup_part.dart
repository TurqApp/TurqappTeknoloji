part of 'sign_in_controller.dart';

extension SignInControllerSignupPart on SignInController {
  Future<void> addToFirestore(BuildContext context) async {
    if (wait.value) return;
    closeKeyboard(context);
    wait.value = true;
    var accountProvisioned = false;
    try {
      final authUser = CurrentUserService.instance.currentAuthUser;
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
      userDoc['agreementAcceptance'] = <String, dynamic>{
        'accepted': true,
        'version': '2026-03-19',
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
        'source': 'signup_email_phone_flow',
        'documents': <String>[
          'agreement',
          'privacy',
          'notice',
          'community',
          'moderation',
        ],
      };
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
        await _trackCurrentAccountForDevice();
        await _persistStoredSessionCredential(
          email: email.value,
          password: password.value,
        );
      } catch (_) {}

      try {
        final storyController = StoryRowController.maybeFind();
        if (storyController == null) return;
        await storyController.loadStories(limit: 100, cacheFirst: false);
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
      } catch (_) {}

      late AgendaController agendaController;
      try {
        agendaController = AgendaController.ensure();

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
        agendaController = AgendaController.ensure();
      }

      try {
        UnreadMessagesController.maybeFind()?.startListeners();
      } catch (_) {}

      wait.value = false;

      await Future.delayed(const Duration(milliseconds: 300));

      _ensureFeedTabSelected();
      Get.off(() => NavBarView());
    } on PhoneAccountLimitReached catch (e) {
      try {
        await CurrentUserService.instance.deleteAuthUserIfPresent();
      } catch (_) {}
      AppSnackbar(
        'signup.limit_title'.tr,
        e.message.isNotEmpty ? e.message : 'signup.limit_body'.tr,
      );
      wait.value = false;
    } on UsernameAlreadyTaken catch (e) {
      try {
        await CurrentUserService.instance.deleteAuthUserIfPresent();
      } catch (_) {}
      AppSnackbar(
        'signup.username_taken_title'.tr,
        e.message.isNotEmpty ? e.message : 'signup.username_taken_body'.tr,
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
        await CurrentUserService.instance.deleteAuthUserIfPresent();
      } catch (_) {}
      AppSnackbar(
        'signup.failed_title'.tr,
        'signup.failed_body'.tr,
      );
    }
  }

  Future<void> searchEmail() async {
    final candidate = normalizeEmailAddress(emailcontroller.text);
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
    final usernameLower = normalizeNicknameInput(nickname.value);
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
    final emailText = normalizeEmailAddress(emailcontroller.text);
    final nicknameText = normalizeNicknameInput(nicknamecontroller.text);
    final pass = passwordcontroller.text;

    try {
      if (!signupPoliciesAccepted.value) {
        AppSnackbar(
          'signup.required_acceptance_title'.tr,
          'signup.required_acceptance_body'.tr,
        );
        return false;
      }
      if (!isValidEmail(emailText)) {
        AppSnackbar('signup.missing_info_title'.tr, 'signup.invalid_email'.tr);
        return false;
      }
      if (nicknameText.length < 8) {
        AppSnackbar('signup.missing_info_title'.tr, 'signup.username_min'.tr);
        return false;
      }

      password.value = pass;
      await verifyPassword();
      if (!passwordAvilable.value) {
        AppSnackbar(
          'signup.weak_password_title'.tr,
          'signup.weak_password_body'.tr,
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
        AppSnackbar('signup.unavailable_title'.tr, 'signup.email_taken'.tr);
        return false;
      }
      if (!availability.nicknameAvailable) {
        AppSnackbar('signup.unavailable_title'.tr, 'signup.username_taken'.tr);
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
    final normalizedEmail = normalizeEmailAddress(email);
    final normalizedNickname = normalizeNicknameInput(nickname ?? '');

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
          'signup.check_failed_title'.tr,
          'signup.check_failed_body'.tr,
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
          'signup.check_failed_title'.tr,
          'signup.check_failed_body'.tr,
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
        'common.warning'.tr,
        'signup.wait_for_new_code'.trParams({'seconds': '${otpTimer.value}'}),
      );
      return;
    }

    final phone = phoneNumber.value.trim();
    if (phone.length != 10 || !phone.startsWith('5')) {
      _logSignupOtp('invalid_phone', {
        'phone': phone,
      });
      AppSnackbar(
        'signup.phone_invalid_title'.tr,
        'signup.phone_invalid_body'.tr,
      );
      return;
    }

    otpRequestInFlight.value = true;
    try {
      final payload = {
        "phone": phone,
        "email": normalizeEmailAddress(email.value),
        "nickname": normalizeNicknameInput(nickname.value),
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
        'common.success'.tr,
        'signup.code_sent_body'.tr,
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
          message = e.message ?? 'signup.otp_invalid_input'.tr;
          break;
        case 'already-exists':
          message = e.message ?? 'signup.otp_already_exists'.tr;
          break;
        case 'failed-precondition':
          message = e.message ?? 'signup.otp_wait_before_resend'.tr;
          break;
        case 'unavailable':
          message = 'signup.sms_unavailable'.tr;
          break;
        default:
          message = 'signup.code_send_failed'.tr;
      }
      AppSnackbar('sign_in.code_send_failed_title'.tr, message);
    } catch (e, st) {
      _logSignupOtp('unexpected_error', {
        'error': e.toString(),
        'stack': st.toString().split('\n').take(3).join(' | '),
      });
      AppSnackbar(
          'sign_in.code_send_failed_title'.tr, 'sign_in.sms_send_failed'.tr);
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
    if (!signupPoliciesAccepted.value) {
      AppSnackbar(
        'signup.required_acceptance_title'.tr,
        'signup.required_acceptance_body'.tr,
      );
      return;
    }
    final phone = phoneNumber.value.trim();
    final code = otpCode.value.trim();

    if (phone.length != 10 || !phone.startsWith('5')) {
      AppSnackbar(
        'signup.phone_invalid_title'.tr,
        'signup.phone_invalid_body'.tr,
      );
      return;
    }
    if (code.length != 6 || int.tryParse(code) == null) {
      AppSnackbar(
        'signup.code_invalid_title'.tr,
        'signup.code_invalid_body'.tr,
      );
      return;
    }

    wait.value = true;
    try {
      await _functions.httpsCallable('verifySignupSmsCode').call({
        "phone": phone,
        "verificationCode": code,
        "email": normalizeEmailAddress(email.value),
        "nickname": normalizeNicknameInput(nickname.value),
      });

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: normalizeEmailAddress(email.value),
        password: password.value.trim(),
      );
      addToFirestore(context);
    } on FirebaseFunctionsException catch (e) {
      wait.value = false;
      String message;
      switch (e.code) {
        case 'deadline-exceeded':
          message = 'signup.code_expired'.tr;
          break;
        case 'already-exists':
          message = e.message ?? 'signup.email_or_username_taken'.tr;
          break;
        case 'not-found':
          message = 'signup.code_not_found'.tr;
          break;
        case 'invalid-argument':
          message = 'signup.code_wrong'.tr;
          break;
        case 'resource-exhausted':
          message = 'signup.too_many_attempts'.tr;
          break;
        case 'failed-precondition':
          message = e.message ?? 'signup.code_no_longer_valid'.tr;
          break;
        default:
          message = 'signup.verify_retry'.tr;
      }
      AppSnackbar('signup.verify_failed_title'.tr, message);
    } on FirebaseAuthException catch (e) {
      wait.value = false;
      final code = e.code;
      String message;
      switch (code) {
        case 'email-already-in-use':
          message = 'signup.email_in_use'.tr;
          break;
        case 'invalid-email':
          message = 'signup.invalid_email_auth'.tr;
          break;
        case 'weak-password':
          message = 'signup.password_too_weak'.tr;
          break;
        case 'operation-not-allowed':
          message = 'signup.email_password_disabled'.tr;
          break;
        case 'network-request-failed':
          message = 'signup.network_failed'.tr;
          break;
        default:
          message = '${e.message ?? 'signup.operation_failed'.tr} ($code)';
      }
      AppSnackbar('signup.account_create_failed_title'.tr, message);
    } catch (_) {
      wait.value = false;
      AppSnackbar(
        'signup.account_create_failed_title'.tr,
        'signup.unexpected_error'.tr,
      );
    }
  }
}
