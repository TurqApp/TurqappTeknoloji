part of 'sign_in.dart';

extension SignInPasswordResetPart on _SignInState {
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
          const SizedBox(height: 12),
          Text(
            'login.reset_password_help'.tr,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "Montserrat",
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 7),
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                  const SizedBox(
                    width: 20,
                    child: Icon(CupertinoIcons.envelope, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, 1),
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
                      : const SizedBox())
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
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
          const SizedBox(height: 7),
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                      offset: const Offset(0, 1),
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
          const SizedBox(height: 15),
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
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
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
                    : const SizedBox();
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
              const SizedBox(height: 12),
              Text(
                'login.password_reset_rule'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "Montserrat",
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 7),
              Obx(
                () => Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                        const SizedBox(
                          width: 20,
                          child: Icon(CupertinoIcons.lock, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Transform.translate(
                            offset: const Offset(0, 1),
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
                        const SizedBox(width: 8),
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
              const SizedBox(height: 15),
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
              const SizedBox(height: 7),
              Obx(
                () => Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                        const SizedBox(
                          width: 20,
                          child: Icon(CupertinoIcons.lock, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Transform.translate(
                            offset: const Offset(0, 1),
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
                        const SizedBox(width: 8),
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
              const SizedBox(height: 15),
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
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
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
                        : const SizedBox();
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
