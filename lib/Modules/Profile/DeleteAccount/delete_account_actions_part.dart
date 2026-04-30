part of 'delete_account.dart';

extension _DeleteAccountActionsPart on _DeleteAccountState {
  Future<void> _sendDeleteCode() async {
    if (_countdown > 0 || _isBusy) return;
    if (_email.isEmpty) {
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        'delete_account.no_email_body'.tr,
      );
      return;
    }

    final user = CurrentUserService.instance.currentAuthUser;
    if (user == null) {
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        'delete_account.session_missing'.tr,
      );
      return;
    }

    _updateViewState(() {
      _isBusy = true;
    });

    try {
      await user.getIdToken(true);
      await AppCloudFunctions.instanceFor(region: "europe-west3")
          .httpsCallable("sendEmailVerificationCode")
          .call({
        "email": _email,
        "purpose": "email_confirm",
        "idToken": await user.getIdToken(),
      });

      _startCountdown();
      _updateViewState(() {
        _isCodeSent = true;
      });
      AppSnackbar(
        'delete_account.code_sent_title'.tr,
        'delete_account.code_sent_body'.tr,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        e.message ?? 'delete_account.send_failed'.tr,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar('common.error'.tr, 'delete_account.send_failed'.tr);
    } finally {
      _updateViewState(() {
        _isBusy = false;
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _updateViewState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 0) {
        timer.cancel();
        return;
      }
      _updateViewState(() {
        _countdown--;
      });
    });
  }

  Future<void> _verifyAndDelete() async {
    if (_email.isEmpty) {
      await _requestDelete(context);
      return;
    }

    final code = _codeController.text.trim();
    if (code.length != 6) {
      AppSnackbar(
        'delete_account.invalid_code_title'.tr,
        'delete_account.invalid_code_body'.tr,
      );
      return;
    }

    final user = CurrentUserService.instance.currentAuthUser;
    if (user == null) {
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        'delete_account.session_missing'.tr,
      );
      return;
    }

    _updateViewState(() {
      _isBusy = true;
    });

    try {
      await user.getIdToken(true);
      final idToken = await user.getIdToken();
      await AppCloudFunctions.instanceFor(region: "europe-west3")
          .httpsCallable("verifyEmailCode")
          .call({
        "email": _email,
        "purpose": "email_confirm",
        "verificationCode": code,
        "idToken": idToken,
      });

      await _requestDelete(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      AppSnackbar(
        'delete_account.no_email_title'.tr,
        e.message ?? 'delete_account.verify_failed'.tr,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar('common.error'.tr, 'delete_account.verify_failed'.tr);
    } finally {
      _updateViewState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _requestDelete(BuildContext context) async {
    final user = CurrentUserService.instance.currentAuthUser;
    if (user == null) return;

    try {
      try {
        await PhoneAccountLimiter()
            .decrementOnUserDelete(uid: user.uid, phone: _phoneNumber);
      } catch (_) {}

      final now = DateTime.now();
      final scheduledAt = now.add(
        const Duration(days: _DeleteAccountState._deletionGraceDays),
      );
      await _userRepository.updateUserFields(
        user.uid,
        {
          "accountStatus": "pending_deletion",
          "isDeleted": true,
          "isPrivate": true,
          "deletionRequestedAt": now.millisecondsSinceEpoch,
          "deletionScheduledAt": scheduledAt.millisecondsSinceEpoch,
          "updatedDate": now.millisecondsSinceEpoch,
        },
        mergeIntoCache: false,
      );

      await _userRepository.addAccountAction(user.uid, {
        "type": "deletion",
        "status": "pending",
        "reason": "self_service_request",
        "createdDate": now.millisecondsSinceEpoch,
        "scheduledAt": scheduledAt.millisecondsSinceEpoch,
      });

      await _hideUserPosts(user.uid);

      await ensureAccountCenterService().removeAccount(user.uid);
      await const SessionExitCoordinator().exitToSignIn(
        reason: SessionExitReason.accountDeleted,
      );
      if (!mounted) return;

      AppSnackbar(
        'delete_account.request_received_title'.tr,
        'delete_account.request_received_body'
            .trParams({'days': '${_DeleteAccountState._deletionGraceDays}'}),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar(
        'common.error'.tr,
        'delete_account.request_failed'.tr,
      );
    }
  }

  Future<void> _hideUserPosts(String uid) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _postRepository.markAllPostsDeletedForUser(uid, nowMs: nowMs);
  }
}
