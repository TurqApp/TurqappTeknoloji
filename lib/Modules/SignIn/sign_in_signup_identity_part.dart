part of 'sign_in.dart';

extension SignInSignupIdentityPart on _SignInState {
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                        child:
                            Icon(CupertinoIcons.envelope, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, 1),
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
              const SizedBox(height: 7),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                      const SizedBox(
                        width: 20,
                        child: Icon(CupertinoIcons.at, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, 1),
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
                      const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                'signup.username_help'.tr,
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              const SizedBox(height: 7),
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                      const SizedBox(
                        width: 20,
                        child: Icon(CupertinoIcons.lock, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, 1),
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
              const SizedBox(height: 4),
              Text(
                'signup.password_help'.tr,
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              const SizedBox(height: 15),
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
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(
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
}
