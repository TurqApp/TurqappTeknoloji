part of 'sign_in.dart';

extension SignInSignupProfilePart on _SignInState {
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
              const SizedBox(height: 12),
              Text(
                'signup.personal_info'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 12),
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
                          offset: const Offset(0, 1),
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
                      const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
                          offset: const Offset(0, 1),
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
                      const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
                      const SizedBox(width: 4),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, 1),
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
                      const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
}
