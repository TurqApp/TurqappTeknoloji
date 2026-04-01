part of 'sign_in_controller.dart';

extension SignInControllerLifecyclePart on SignInController {
  void _handleLifecycleInit() {
    _startBrandTypewriter();
    _selectionWorker = ever<int>(selection, (value) {
      if (value == 0 || value == 1) {
        _startBrandTypewriter();
      }
    });

    emailFocus.value.addListener(() => emailFocus.refresh());
    passwordFocus.value.addListener(() => passwordFocus.refresh());
    nicknameFocus.value.addListener(() => nicknameFocus.refresh());
    firstNameFocus.value.addListener(() => firstNameFocus.refresh());
    lastNameFocus.value.addListener(() => lastNameFocus.refresh());
    phoneNumberFocus.value.addListener(() => phoneNumberFocus.refresh());
    resetMailFocus.value.addListener(() => resetMailFocus.refresh());
    otpFocus.value.addListener(() => otpFocus.refresh());
    resetOtpFocus.value.addListener(() => otpFocus.refresh());
    newPasswordFocus.value.addListener(() => newPasswordFocus.refresh());
    newPasswordRepeatFocus.value.addListener(
      () => newPasswordRepeatFocus.refresh(),
    );

    phoneNumberController.addListener(() {
      phoneNumber.value = phoneNumberController.text;
      _validateForm();
    });
    firstNameController.addListener(() {
      firstName.value = firstNameController.text;
      _validateForm();
    });
    lastNameController.addListener(() {
      lastName.value = lastNameController.text;
      _validateForm();
    });
    otpController.addListener(() {
      otpCode.value = otpController.text;
    });
    passwordcontroller.addListener(() {
      password.value = passwordcontroller.text;
    });
    nicknamecontroller.addListener(() {
      nickname.value = nicknamecontroller.text;
    });
    emailcontroller.addListener(() {
      email.value = emailcontroller.text;
    });
    resetMailController.addListener(() {
      resetMail.value = resetMailController.text;
    });
    resetOtpController.addListener(() {
      resetOtp.value = resetOtpController.text;
    });
    newPasswordController.addListener(() {
      newPassword.value = newPasswordController.text;
    });
    newPasswordRepeatController.addListener(() {
      newPasswordRepeat.value = newPasswordRepeatController.text;
    });
  }

  void _handleLifecycleClose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    nicknamecontroller.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    otpController.dispose();
    resetMailController.dispose();
    resetOtpController.dispose();
    newPasswordController.dispose();
    newPasswordRepeatController.dispose();
    _timer?.cancel();
    _timerReset?.cancel();
    _emailAvailabilityDebounce?.cancel();
    _nicknameAvailabilityDebounce?.cancel();
    _typewriterTimer?.cancel();
    _cursorBlinkTimer?.cancel();
    _selectionWorker?.dispose();
  }

  String get typedBrandText => _loginWord.substring(
      0,
      typedBrandLength.value.clamp(
        0,
        _loginWord.length,
      ));

  void _startBrandTypewriter() {
    _typewriterTimer?.cancel();
    _cursorBlinkTimer?.cancel();
    typedBrandLength.value = 1;
    showBrandCursor.value = true;

    final remainingChars = (_loginWord.length - 1).clamp(0, _loginWord.length);
    if (remainingChars == 0) {
      showBrandCursor.value = false;
      return;
    }

    _typewriterTimer = Timer.periodic(
      const Duration(milliseconds: 110),
      (timer) {
        if (isClosed) {
          timer.cancel();
          return;
        }
        if (typedBrandLength.value >= _loginWord.length) {
          showBrandCursor.value = false;
          timer.cancel();
          return;
        }
        typedBrandLength.value += 1;
      },
    );

    _cursorBlinkTimer = Timer.periodic(
      const Duration(milliseconds: 220),
      (timer) {
        if (isClosed) {
          timer.cancel();
          return;
        }
        if (typedBrandLength.value >= _loginWord.length) {
          showBrandCursor.value = false;
          timer.cancel();
          return;
        }
        showBrandCursor.value = !showBrandCursor.value;
      },
    );
  }

  void _validateForm() {
    final valid = firstNameController.text.trim().length >= 3 &&
        phoneNumberController.text.trim().length == 10 &&
        phoneNumberController.text.trim().startsWith("5");
    isFormValid.value = valid;
  }
}
