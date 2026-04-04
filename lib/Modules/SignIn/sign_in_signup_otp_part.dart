part of 'sign_in.dart';

extension SignInSignupOtpPart on _SignInState {
  Widget create3(BuildContext context) {
    return Expanded(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'signup.step'.trParams({
                  'current': '${controller.selection.value - 1}',
                }),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 7),
              Text(
                'signup.verification_message'.trParams({
                  'phone': controller.phoneNumber.value,
                }),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                      const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
}
