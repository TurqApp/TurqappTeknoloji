part of 'sign_in.dart';

extension SignInSignupPart on SignIn {
  Widget create1() {
    return Expanded(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'signup.step'.tr.replaceAll(
                    '{current}', '${controller.selection.value - 1}'),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'signup.create_account_title'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1EA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => controller.signupPoliciesAccepted.value =
                          !controller.signupPoliciesAccepted.value,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: controller.signupPoliciesAccepted.value
                                  ? Colors.black
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black),
                            ),
                            child: controller.signupPoliciesAccepted.value
                                ? const Icon(
                                    CupertinoIcons.check_mark,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  height: 1.55,
                                  fontFamily: 'Montserrat',
                                ),
                                children: [
                                  _policyCenterTextSpan(
                                    'signup.policy_short'.tr,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
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
                        child:
                            Icon(CupertinoIcons.envelope, color: Colors.grey),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, 1),
                          child: TextField(
                            controller: controller.emailcontroller,
                            focusNode: controller.emailFocus.value,
                            onTap: () {
                              controller.emailFocus.value.requestFocus();
                            },
                            maxLength: 40,
                            decoration: InputDecoration(
                              hintText: 'signup.email'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                            onChanged: (txt) {
                              controller.scheduleEmailAvailabilityCheck();
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        child: Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: controller.emailAvilable.value
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 7),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: controller.nicknameFocus.value.hasFocus
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
                        child: Icon(CupertinoIcons.at, color: Colors.grey),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, 1),
                          child: TextField(
                            controller: controller.nicknamecontroller,
                            focusNode: controller.nicknameFocus.value,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(25),
                              CustomNicknameFormatter(),
                            ],
                            onTap: () {
                              controller.nicknameFocus.value.requestFocus();
                            },
                            onChanged: (txt) {
                              if (txt.length >= 8) {
                                controller.scheduleNicknameAvailabilityCheck();
                              } else {
                                controller.nicknameAvilable.value = false;
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'signup.username'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 20,
                        child: Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: controller.nicknameAvilable.value
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'signup.username_help'.tr,
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
              SizedBox(height: 7),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: controller.passwordFocus.value.hasFocus
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
                            controller: controller.passwordcontroller,
                            focusNode: controller.passwordFocus.value,
                            onTap: () {
                              controller.passwordFocus.value.requestFocus();
                            },
                            maxLength: 40,
                            onChanged: (v) {
                              if (v.length >= 6) {
                                controller.verifyPassword();
                              } else {
                                controller.passwordAvilable.value = false;
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'signup.password'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            obscureText: true,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        child: Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: controller.passwordAvilable.value
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'signup.password_help'.tr,
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      controller.nicknamecontroller.text = "";
                      controller.emailcontroller.text = "";
                      controller.passwordcontroller.text = "";
                      controller.signupPoliciesAccepted.value = false;
                      controller.emailFocus.value.unfocus();
                      controller.nicknameFocus.value.unfocus();
                      controller.passwordFocus.value.unfocus();
                      controller.clearStoredAccountContext();
                      controller.selection.value = 0;
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
                  GestureDetector(
                    onTap: controller.signupIdentityCheckLoading.value
                        ? null
                        : () async {
                            final canContinue =
                                await controller.validateSignupIdentityStep();
                            if (!canContinue) return;

                            controller.emailFocus.value.unfocus();
                            controller.nicknameFocus.value.unfocus();
                            controller.passwordFocus.value.unfocus();
                            controller.selection.value = 3;
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
                      child: controller.signupIdentityCheckLoading.value
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              'signup.next'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget create2() {
    return Expanded(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'signup.step'.tr.replaceAll(
                    '{current}', '${controller.selection.value - 1}'),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              SizedBox(height: 12),
              Text(
                'signup.personal_info'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: controller.firstNameFocus.value.hasFocus
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
                            controller: controller.firstNameController,
                            focusNode: controller.firstNameFocus.value,
                            onTap: () {
                              controller.firstNameFocus.value.requestFocus();
                            },
                            maxLength: 25,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(
                                r"^[a-zA-ZçÇğĞıİöÖşŞüÜ0-9\s\u{1F600} \u{1F64F}]{1,25}$",
                                unicode: true,
                              )),
                            ],
                            onChanged: (val) {
                              final capitalized = _capitalizeWords(val);
                              controller.firstNameController.value =
                                  controller.firstNameController.value.copyWith(
                                text: capitalized,
                                selection: TextSelection.collapsed(
                                  offset: capitalized.length,
                                ),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'signup.first_name'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Obx(() => Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: controller.firstName.value.length >= 3
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: controller.lastNameFocus.value.hasFocus
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
                            controller: controller.lastNameController,
                            focusNode: controller.lastNameFocus.value,
                            onTap: () {
                              controller.lastNameFocus.value.requestFocus();
                            },
                            maxLength: 40,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(
                                r"^[a-zA-ZçÇğĞıİöÖşŞüÜ0-9\s\u{1F600}\u{1F64F}]{1,25}$",
                                unicode: true,
                              )),
                            ],
                            onChanged: (val) {
                              controller.lastNameController.value =
                                  controller.lastNameController.value.copyWith(
                                text: _capitalizeWords(val),
                                selection: TextSelection.collapsed(
                                  offset: _capitalizeWords(val).length,
                                ),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'signup.last_name_optional'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Obx(() => Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: controller.lastName.value.length >= 2
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: controller.phoneNumberFocus.value.hasFocus
                        ? Colors.blueAccent
                        : Colors.transparent,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 25,
                          height: 25,
                          child: Image.asset(
                            "assets/images/turkey.webp",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, 1),
                          child: TextField(
                            controller: controller.phoneNumberController,
                            focusNode: controller.phoneNumberFocus.value,
                            onTap: () {
                              controller.phoneNumberFocus.value.requestFocus();
                            },
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'signup.phone_hint'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Obx(() => Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: (controller.phoneNumber.value
                                        .startsWith("5") &&
                                    controller.phoneNumber.value.length == 10)
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      controller.firstNameController.text = "";
                      controller.lastNameController.text = "";
                      controller.phoneNumberController.text = "";
                      controller.firstNameFocus.value.unfocus();
                      controller.lastNameFocus.value.unfocus();
                      controller.phoneNumberFocus.value.unfocus();
                      controller.selection.value--;
                    },
                    child: Container(
                      width: 80,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
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
                  GestureDetector(
                    onTap: controller.otpRequestInFlight.value
                        ? null
                        : () {
                            final nameOk = controller.firstNameController.text
                                    .trim()
                                    .length >=
                                3;
                            final phone =
                                controller.phoneNumberController.text.trim();
                            final phoneOk =
                                phone.length == 10 && phone.startsWith('5');
                            if (!nameOk || !phoneOk) {
                              AppSnackbar(
                                'signup.missing_info_title'.tr,
                                'signup.phone_name_rule'.tr,
                              );
                              return;
                            }

                            controller.otpController.text = "";
                            controller.sendOtpCode();
                          },
                    child: Container(
                      width: 80,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: controller.otpRequestInFlight.value
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              'signup.next'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget create3(BuildContext context) {
    return Expanded(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'signup.step'.tr.replaceAll(
                    '{current}', '${controller.selection.value - 1}'),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'signup.verification_title'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7),
              Text(
                'signup.verification_message'
                    .tr
                    .replaceAll('{phone}', controller.phoneNumber.value),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: controller.otpFocus.value.hasFocus
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
                            controller: controller.otpController,
                            focusNode: controller.otpFocus.value,
                            onTap: () {
                              controller.otpFocus.value.requestFocus();
                            },
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: 'signup.code_hint'.tr,
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Obx(() => GestureDetector(
                            onTap: controller.otpRequestInFlight.value
                                ? null
                                : controller.otpTimer.value == 0
                                    ? () => controller.sendOtpCode()
                                    : null,
                            child: Text(
                              !controller.signupCodeRequested.value
                                  ? 'login.get_code'.tr
                                  : controller.otpTimer.value == 0
                                      ? 'login.resend_code'.tr
                                      : "${'login.resend_code'.tr} (${controller.otpTimer.value} sn)",
                              style: TextStyle(
                                color: controller.otpRequestInFlight.value
                                    ? Colors.grey
                                    : controller.otpTimer.value == 0
                                        ? Colors.blueAccent
                                        : Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      controller.otpController.text = "";
                      controller.firstNameFocus.value.unfocus();
                      controller.lastNameFocus.value.unfocus();
                      controller.phoneNumberFocus.value.unfocus();
                      controller.selection.value--;
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
                  GestureDetector(
                    onTap: controller.wait.value
                        ? null
                        : () async {
                            await controller.verifySignupOtpAndCreateAccount(
                              context,
                            );
                          },
                    child: Container(
                      width: 80,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  String _capitalizeWords(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
