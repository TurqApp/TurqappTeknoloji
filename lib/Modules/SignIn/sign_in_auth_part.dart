part of 'sign_in.dart';

extension SignInAuthPart on _SignInState {
  Widget _brandTypewriter() {
    return _LoginBrandTypewriter(
      key: ValueKey('login-brand-${controller.selection.value}'),
    );
  }

  Widget startScreen() {
    final accountCenter = AccountCenterService.ensure();
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _brandTypewriter(),
                const SizedBox(height: 10),
                Text(
                  'login.tagline'.tr,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final accounts = accountCenter.accounts.toList(growable: false);
            if (accounts.isEmpty) return const SizedBox.shrink();
            final visible = accounts.take(3).toList(growable: false);
            return Column(
              children: [
                if (accountCenter.lastUsedAccount != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(
                          'login.device_accounts'.tr,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final account in visible) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await controller.continueWithStoredAccount(account);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.black12,
                              backgroundImage: account.avatarUrl.trim().isEmpty
                                  ? null
                                  : NetworkImage(account.avatarUrl.trim()),
                              child: account.avatarUrl.trim().isEmpty
                                  ? Text(
                                      account.displayName.trim().isNotEmpty
                                          ? account.displayName
                                              .trim()[0]
                                              .toUpperCase()
                                          : '@',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'MontserratBold',
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.displayName.trim().isNotEmpty
                                        ? account.displayName
                                        : '@${account.username}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${account.username}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    accountCenter.lastUsedUid.value ==
                                            account.uid
                                        ? 'login.last_used'.tr
                                        : 'login.saved_account'.tr,
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 11,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              color: Colors.black38,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
              ],
            );
          }),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                controller.clearStoredAccountContext();
                controller.selection.value = 1;
              },
              child: Ink(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Center(
                  child: Text(
                    'login.sign_in'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () {
              controller.clearStoredAccountContext();
              controller.signupPoliciesAccepted.value = false;
              controller.selection.value = 2;
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(50),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Text(
                'login.create_account'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            "© TurqApp A.Ş.",
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    );
  }

  Widget signin() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: bottomInset > 0
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          _brandTypewriter(),
                          const SizedBox(height: 7),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Obx(() {
                    final account = controller.selectedStoredAccount.value;
                    if (account == null) return const SizedBox.shrink();
                    String message;
                    switch (account.primaryProvider) {
                      case 'phone':
                        message = 'login.selected_account_phone'
                            .tr
                            .replaceAll('{username}', '@${account.username}');
                        break;
                      case 'password':
                        message = 'login.selected_account_password'
                            .tr
                            .replaceAll('{username}', '@${account.username}');
                        break;
                      default:
                        message = 'login.selected_account_manual'
                            .tr
                            .replaceAll('{username}', '@${account.username}');
                        break;
                    }
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withAlpha(14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          height: 1.35,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    );
                  }),
                  AutofillGroup(
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            border: Border.all(
                              color: controller.emailFocus.value.hasFocus
                                  ? Colors.blueAccent
                                  : Colors.transparent,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Icon(
                                    CupertinoIcons.person,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Transform.translate(
                                    offset: Offset(0, 1),
                                    child: TextField(
                                      controller: controller.emailcontroller,
                                      focusNode: controller.emailFocus.value,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                        AutofillHints.email,
                                      ],
                                      onTap: () {
                                        controller.emailFocus.value
                                            .requestFocus();
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'login.identifier_hint'.tr,
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: "MontserratMedium",
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                      onChanged: (v) {
                                        String trimmedValue = v.trim();
                                        if (trimmedValue != v) {
                                          controller.emailcontroller.text =
                                              trimmedValue;
                                          controller.emailcontroller.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                              offset: trimmedValue.length,
                                            ),
                                          );
                                        }
                                        controller
                                            .maybeClearStoredAccountContextForIdentifier(
                                          trimmedValue,
                                        );
                                        if (trimmedValue.isEmpty) {
                                          controller.signInEmail.value = "";
                                        } else if (trimmedValue.length >= 5) {
                                          controller.nicknameFinder();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 7),
                        Obx(() {
                          final hasPassword =
                              controller.password.value.trim().isNotEmpty;
                          return Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              border: Border.all(
                                color: controller.passwordFocus.value.hasFocus
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    child: Icon(
                                      CupertinoIcons.lock,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Transform.translate(
                                      offset: Offset(0, 1),
                                      child: TextField(
                                        controller:
                                            controller.passwordcontroller,
                                        focusNode:
                                            controller.passwordFocus.value,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        onTap: () {
                                          controller.passwordFocus.value
                                              .requestFocus();
                                        },
                                        onChanged: (v) {
                                          controller.password.value = v;
                                          if (v.isEmpty) {
                                            controller.showPassword.value =
                                                false;
                                          }
                                          if (v.length >= 6) {
                                            controller.verifyPassword();
                                          } else {
                                            controller.passwordAvilable.value =
                                                false;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'login.password_hint'.tr,
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                            fontFamily: "MontserratMedium",
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        obscureText:
                                            !controller.showPassword.value,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  if (hasPassword)
                                    GestureDetector(
                                      onTap: () {
                                        controller.showPassword.value =
                                            !controller.showPassword.value;
                                      },
                                      child: Icon(
                                        controller.showPassword.value
                                            ? CupertinoIcons.eye
                                            : CupertinoIcons.eye_slash,
                                        color: Colors.blueAccent,
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () {
                                        controller.resetMailController.clear();
                                        controller.resetOtpController.clear();
                                        controller.clearStoredAccountContext();
                                        controller.selection.value = 5;
                                      },
                                      child: Text(
                                        'login.reset'.tr,
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.emailcontroller.text = "";
                          controller.passwordcontroller.text = "";
                          controller.emailFocus.value.unfocus();
                          controller.passwordFocus.value.unfocus();
                          controller.clearStoredAccountContext();
                          controller.selection.value--;
                        },
                        child: Container(
                          width: 80,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            'common.back'.tr,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: controller.wait.value
                              ? null
                              : () async {
                                  final mailOrNick =
                                      controller.emailcontroller.text.trim();
                                  final pass =
                                      controller.passwordcontroller.text;
                                  if (mailOrNick.isEmpty || pass.isEmpty) {
                                    AppSnackbar(
                                      'common.warning'.tr,
                                      'sign_in.enter_credentials'.tr,
                                    );
                                    return;
                                  }
                                  if (pass.length < 6) {
                                    AppSnackbar(
                                      'sign_in.invalid_password_title'.tr,
                                      'sign_in.invalid_password_body'.tr,
                                    );
                                    return;
                                  }
                                  controller.wait.value = true;
                                  await controller.signIn();
                                },
                          child: Ink(
                            width: 80,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: controller.wait.value
                                  ? const CupertinoActivityIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'common.continue'.tr,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget resetPassword() {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'login.reset_password_title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'login.reset_password_help'.tr,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "Montserrat",
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'login.email_label'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ],
          ),
          SizedBox(height: 7),
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.all(Radius.circular(12)),
              border: Border.all(
                color: controller.resetMailFocus.value.hasFocus
                    ? Colors.blueAccent
                    : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Icon(CupertinoIcons.envelope, color: Colors.grey),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, 1),
                      child: TextField(
                        controller: controller.resetMailController,
                        focusNode: controller.resetMailFocus.value,
                        onTap: () {
                          controller.resetMailFocus.value.requestFocus();
                        },
                        onChanged: (txt) {
                          final trimmedValue = txt.trim();
                          if (trimmedValue != txt) {
                            controller.resetMailController.text = trimmedValue;
                            controller.resetMailController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: trimmedValue.length),
                            );
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'login.email_hint'.tr,
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "MontserratMedium",
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                  Obx(() => controller.isValidEmail(controller.resetMail.value)
                      ? GestureDetector(
                          onTap: controller.resetOtpRequestInFlight.value
                              ? null
                              : controller.otpTimerReset.value == 0
                                  ? () => controller.sendOtpCodeForReset()
                                  : null,
                          child: Text(
                            !controller.resetCodeRequested.value
                                ? 'login.get_code'.tr
                                : controller.otpTimerReset.value == 0
                                    ? 'login.resend_code'.tr
                                    : "${'login.resend_code'.tr} (${controller.otpTimerReset.value} sn)",
                            style: TextStyle(
                              color: controller.resetOtpRequestInFlight.value
                                  ? Colors.grey
                                  : controller.otpTimerReset.value == 0
                                      ? Colors.blueAccent
                                      : Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : SizedBox())
                ],
              ),
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Text(
                'login.verification_code'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ],
          ),
          SizedBox(height: 7),
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.all(Radius.circular(12)),
              border: Border.all(
                color: controller.resetOtpFocus.value.hasFocus
                    ? Colors.blueAccent
                    : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, 1),
                      child: TextField(
                        controller: controller.resetOtpController,
                        focusNode: controller.resetOtpFocus.value,
                        onTap: () {
                          controller.resetOtpFocus.value.requestFocus();
                        },
                        decoration: InputDecoration(
                          hintText: 'login.verification_code_hint'.tr,
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "MontserratMedium",
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  controller.resetMailController.text = "";
                  controller.resetMailFocus.value.unfocus();
                  controller.clearStoredAccountContext();
                  controller.selection.value = 1;
                },
                child: Container(
                  width: 80,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(
                    'common.back'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
              Obx(() {
                return controller.resetOtp.value != ""
                    ? GestureDetector(
                        onTap: () async {
                          await controller.verifyResetSmsCode();
                        },
                        child: Container(
                          width: 80,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            'common.continue'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      )
                    : SizedBox();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget createNewPassword() {
    return Expanded(
      child: SingleChildScrollView(
        child: AutofillGroup(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'login.reset_password_title'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'login.password_reset_rule'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "Montserrat",
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'login.new_password_label'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7),
              Obx(
                () => Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: controller.resetMailFocus.value.hasFocus
                          ? Colors.blueAccent
                          : Colors.transparent,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Icon(CupertinoIcons.lock, color: Colors.grey),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(0, 1),
                            child: TextField(
                              controller: controller.newPasswordController,
                              focusNode: controller.newPasswordFocus.value,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              obscureText: !controller.showNewPassword.value,
                              onTap: () {
                                controller.newPasswordFocus.value
                                    .requestFocus();
                              },
                              decoration: InputDecoration(
                                hintText: 'login.new_password_hint'.tr,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: "MontserratMedium",
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            controller.showNewPassword.value =
                                !controller.showNewPassword.value;
                          },
                          child: Icon(
                            controller.showNewPassword.value
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    'login.repeat_new_password'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7),
              Obx(
                () => Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: controller.resetOtpFocus.value.hasFocus
                          ? Colors.blueAccent
                          : Colors.transparent,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Icon(CupertinoIcons.lock, color: Colors.grey),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(0, 1),
                            child: TextField(
                              controller:
                                  controller.newPasswordRepeatController,
                              focusNode:
                                  controller.newPasswordRepeatFocus.value,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              obscureText:
                                  !controller.showNewPasswordRepeat.value,
                              onTap: () {
                                controller.newPasswordRepeatFocus.value
                                    .requestFocus();
                              },
                              decoration: InputDecoration(
                                hintText: 'login.repeat_new_password_hint'.tr,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: "MontserratMedium",
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            controller.showNewPasswordRepeat.value =
                                !controller.showNewPasswordRepeat.value;
                          },
                          child: Icon(
                            controller.showNewPasswordRepeat.value
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      controller.newPasswordController.text = "";
                      controller.newPasswordRepeatController.text = "";
                      controller.newPasswordFocus.value.unfocus();
                      controller.newPasswordRepeatFocus.value.unfocus();
                      controller.selection.value = 1;
                      controller.wait.value = false;
                    },
                    child: Container(
                      width: 80,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Text(
                        'common.back'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    return controller.newPassword.value ==
                                controller.newPasswordRepeat.value &&
                            controller.wait.value == false
                        ? GestureDetector(
                            onTap: () {
                              controller.setNewPassword(
                                controller.newPassword.value,
                              );
                            },
                            child: Container(
                              width: 80,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                'common.continue'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          )
                        : SizedBox();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBrandTypewriter extends StatefulWidget {
  const _LoginBrandTypewriter({super.key});

  @override
  State<_LoginBrandTypewriter> createState() => _LoginBrandTypewriterState();
}

class _LoginBrandTypewriterState extends State<_LoginBrandTypewriter> {
  static const String _word = 'TurqApp';
  Timer? _typingTimer;
  Timer? _cursorTimer;
  Timer? _betaTimer;
  int _typedLength = 0;
  bool _showCursor = true;
  bool _showBeta = false;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _betaTimer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _typedLength = 1;
    _showCursor = true;
    _showBeta = false;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 110), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _word.length) {
        timer.cancel();
        _showCursor = false;
        _betaTimer?.cancel();
        _betaTimer = Timer(const Duration(milliseconds: 140), () {
          if (!mounted) return;
          setState(() {
            _showBeta = true;
          });
        });
        setState(() {});
        return;
      }
      setState(() {
        _typedLength += 1;
      });
    });

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _word.length) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _word.substring(0, _typedLength.clamp(0, _word.length)),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 58,
            fontFamily: 'Noe',
            letterSpacing: 1.0,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: _showCursor ? 5 : 0,
          margin: EdgeInsets.only(right: _showBeta ? 3 : 0),
          child: AnimatedOpacity(
            opacity: _showCursor ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: 3,
              height: 50,
              color: Colors.black,
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _showBeta ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'BETA',
              style: TextStyle(
                color: Colors.black38,
                fontSize: 11,
                letterSpacing: 1.8,
                fontFamily: 'MontserratSemiBold',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
