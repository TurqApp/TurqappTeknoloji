part of 'sign_in.dart';

extension SignInSignInPart on _SignInState {
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
                  const SizedBox(height: 12),
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
                            borderRadius: const BorderRadius.all(
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
                                const SizedBox(
                                  width: 20,
                                  child: Icon(
                                    CupertinoIcons.person,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Transform.translate(
                                    offset: const Offset(0, 1),
                                    child: TextField(
                                      key: const ValueKey('email'),
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
                                        final trimmedValue = v.trim();
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
                        const SizedBox(height: 7),
                        Obx(() {
                          final hasPassword =
                              controller.password.value.trim().isNotEmpty;
                          return Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: const BorderRadius.all(
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
                                  const SizedBox(
                                    width: 20,
                                    child: Icon(
                                      CupertinoIcons.lock,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Transform.translate(
                                      offset: const Offset(0, 1),
                                      child: TextField(
                                        key: const ValueKey('password'),
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
                                  const SizedBox(width: 12),
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
                  const SizedBox(height: 18),
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
                          key: const ValueKey('login_submit_button'),
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
}
