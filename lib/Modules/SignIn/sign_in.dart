import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Core/Helpers/custom_nickname_formatter.dart';

class SignIn extends StatelessWidget {
  SignIn({super.key});
  final controller = Get.put(SignInController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (controller.selection.value == 0)
                  startScreen()
                else if (controller.selection.value == 1)
                  signin()
                else if (controller.selection.value == 2)
                  create1()
                else if (controller.selection.value == 3)
                  create2()
                else if (controller.selection.value == 4)
                  create3(context)
                else if (controller.selection.value == 5)
                  resetPassword()
                else if (controller.selection.value == 6)
                  createNewPassword()
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget startScreen() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: controller.animationController,
                  child: Image.asset(
                    "assets/images/logotrans.webp",
                    color: Colors.black,
                    height: 80,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "TurqApp",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 35,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.selection.value = 1;
            },
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Text(
                "Giriş Yap",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "MontserratBold",
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () {
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
                "Hesap Oluştur",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  RotationTransition(
                    turns: controller.animationController,
                    child: Image.asset(
                      "assets/images/logotrans.webp",
                      color: Colors.black,
                      height: 80,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "TurqApp",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 35,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  SizedBox(height: 7),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          AutofillGroup(
            child: Column(
              children: [
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
                              Icon(CupertinoIcons.person, color: Colors.black),
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
                                controller.emailFocus.value.requestFocus();
                              },
                              decoration: InputDecoration(
                                hintText:
                                    "Kullanıcı adı veya e-posta adresiniz",
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
                                    TextPosition(offset: trimmedValue.length),
                                  );
                                }
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
                          child: Icon(CupertinoIcons.lock, color: Colors.black),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(0, 1),
                            child: TextField(
                              controller: controller.passwordcontroller,
                              focusNode: controller.passwordFocus.value,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onTap: () {
                                controller.passwordFocus.value.requestFocus();
                              },
                              onChanged: (v) {
                                if (v.length >= 6) {
                                  controller.verifyPassword();
                                } else {
                                  controller.passwordAvilable.value = false;
                                }
                              },
                              decoration: InputDecoration(
                                hintText: "Şifreniz",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: "MontserratMedium",
                                ),
                                border: InputBorder.none,
                              ),
                              obscureText: !controller.showPassword.value,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        if (controller.password.value.trim().isNotEmpty)
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
                              controller.selection.value = 5;
                            },
                            child: Text(
                              "Sıfırla",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium"),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // geri
              GestureDetector(
                onTap: () {
                  controller.emailcontroller.text = "";
                  controller.passwordcontroller.text = "";
                  controller.emailFocus.value.unfocus();
                  controller.passwordFocus.value.unfocus();
                  controller.selection.value--;
                },
                child: Container(
                  width: 80,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Text(
                    "Geri",
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
                        final mailOrNick =
                            controller.emailcontroller.text.trim();
                        final pass = controller.passwordcontroller.text;
                        if (mailOrNick.isEmpty || pass.isEmpty) {
                          AppSnackbar('Eksik Bilgi',
                              'Kullanıcı adı/e-posta ve şifre girin.');
                          return;
                        }
                        if (pass.length < 6) {
                          AppSnackbar(
                              'Hatalı Şifre', 'Şifre en az 6 karakter olmalı.');
                          return;
                        }
                        controller.wait.value = true;
                        await controller.signIn();
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
                      : const Text(
                          "Devam",
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
  }

  Widget create1() {
    return Expanded(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Adım ${controller.selection.value - 1}/3",
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
                    "Hesabınızı Oluşturun",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Satır hizasını üstte tutar
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: "Montserrat",
                        ),
                        children: [
                          const TextSpan(
                            text: "Hesap oluşturarak ",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: "Montserrat",
                            ),
                          ),
                          TextSpan(
                            text: "Son Kullanıcı Sözleşmesini",
                            style: const TextStyle(
                              color: Colors.blue, // Mavi renk
                              decoration: TextDecoration
                                  .underline, // İsteğe bağlı alt çizgi
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(Uri.parse("https://turqapp.com"));
                              },
                          ),
                          const TextSpan(
                            text: " kabul etmiş olursunuz.",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: "Montserrat",
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                            maxLength: 40, // sınır eklendi
                            decoration: InputDecoration(
                              hintText: "E-Posta",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "", // sayaç yazısını gizle
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
                              hintText: "Kullanıcı Adı",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "", // sayaç yazısı gizle
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
              SizedBox(
                height: 4,
              ),
              Text(
                "Kullanıcı adı size özel, özgün ve yanıltıcı olmayan şekilde oluşturulmalıdır. Türkçe karakterler otomatik dönüştürülür.",
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
                            maxLength: 40, // sınır eklendi
                            onChanged: (v) {
                              if (v.length >= 6) {
                                controller.verifyPassword();
                              } else {
                                controller.passwordAvilable.value = false;
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "Şifre",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                              border: InputBorder.none,
                              counterText: "", // sayaç yazısı gizle
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
              SizedBox(
                height: 4,
              ),
              Text(
                "Şifre (En az bir harf, bir sayı, bir noktalama; min 6 karakter)",
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // geri
                  GestureDetector(
                    onTap: () {
                      controller.nicknamecontroller.text = "";
                      controller.emailcontroller.text = "";
                      controller.passwordcontroller.text = "";
                      controller.emailFocus.value.unfocus();
                      controller.nicknameFocus.value.unfocus();
                      controller.passwordFocus.value.unfocus();
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
                      child: const Text(
                        "Geri",
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
                          : const Text(
                              "İleri",
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
                "Adım ${controller.selection.value - 1}/3",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),

              SizedBox(height: 12),

              Text(
                "Kişisel Bilgiler",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),

              SizedBox(height: 12),

              // Ad
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
                                  unicode: true)),
                            ],
                            onChanged: (val) {
                              final capitalized = _capitalizeWords(val);
                              controller.firstNameController.value =
                                  controller.firstNameController.value.copyWith(
                                text: capitalized,
                                selection: TextSelection.collapsed(
                                    offset: capitalized.length),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: "Ad",
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

              // Soyad
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
                                  unicode: true)),
                            ],
                            onChanged: (val) {
                              controller.lastNameController.value =
                                  controller.lastNameController.value.copyWith(
                                text: _capitalizeWords(val),
                                selection: TextSelection.collapsed(
                                    offset: _capitalizeWords(val).length),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: "Soyad (Opsiyonel)",
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

              // Telefon
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
                          child: Image.asset("assets/images/turkey.webp",
                              fit: BoxFit.cover),
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
                              hintText: "(555)xxxxxxx",
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
                      child: const Text(
                        "Geri",
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
                      final nameOk =
                          controller.firstNameController.text.trim().length >=
                              3;
                      final phone =
                          controller.phoneNumberController.text.trim();
                      final phoneOk =
                          phone.length == 10 && phone.startsWith('5');
                      if (!nameOk || !phoneOk) {
                        AppSnackbar('Eksik Bilgi',
                            'Ad en az 3 karakter olmalı ve telefon 5 ile başlayan 10 hane olmalı.');
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
                          : const Text(
                              "İleri",
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
                "Adım ${controller.selection.value - 1}/3",
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
                    "Doğrulama",
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
                "+90${controller.phoneNumber.value} telefon numaranıza bir doğrulama kodu gönderdik. Bu doğrulama kodunu girerek devam edebilirsiniz.",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              SizedBox(
                height: 12,
              ),
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
                              counterText: "", // Sayaç görünmesin
                              hintText: "6 haneli kod",
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
                      SizedBox(
                        width: 12,
                      ),
                      Obx(() => GestureDetector(
                            onTap: controller.otpRequestInFlight.value
                                ? null
                                : controller.otpTimer.value == 0
                                ? () => controller.sendOtpCode()
                                : null,
                            child: Text(
                              !controller.signupCodeRequested.value
                                  ? "Kodu Al"
                                  : controller.otpTimer.value == 0
                                      ? "Tekrar Gönder"
                                      : "Tekrar Gönder (${controller.otpTimer.value} sn)",
                              style: TextStyle(
                                color: controller.otpRequestInFlight.value
                                    ? Colors.grey
                                    : controller.otpTimer.value == 0
                                    ? Colors.blueAccent
                                    : Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ))
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // geri
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
                      child: const Text(
                        "Geri",
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
                          : const Text(
                              "Devam",
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
        .replaceAll(RegExp(r'\s+'), ' ') // birden fazla boşluğu teke indir
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
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
                  "Şifreni Sıfırla",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            "Mail adresinizi girerek hesabınızı bulmamızda yardımcı olun. Hesabınızda kayıt olan telefon numaranıza bir doğrulama kodu göndereceğiz",
            style: TextStyle(
                color: Colors.black, fontSize: 15, fontFamily: "Montserrat"),
          ),
          SizedBox(
            height: 12,
          ),
          Row(
            children: [
              Text(
                "E-posta Adresi",
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
                          hintText: "E-posta adresinizi girin",
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
                                ? "Kodu Al"
                                : controller.otpTimerReset.value == 0
                                    ? "Tekrar Gönder"
                                    : "Tekrar Gönder (${controller.otpTimerReset.value} sn)",
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
                "Doğrulama Kodu",
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
                          hintText: "6 haneli doğrulama kodu",
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
              // geri
              GestureDetector(
                onTap: () {
                  controller.resetMailController.text = "";
                  controller.resetMailFocus.value.unfocus();
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
                  child: const Text(
                    "Geri",
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
                          child: const Text(
                            "Devam",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      )
                    : SizedBox();
              })
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
                      "Şifreni Sıfırla",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                "En az bir karakteri büyük olmalı ve en az 6 karakterden oluşmalıdır.",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat"),
              ),
              SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  Text(
                    "Yeni Şifre",
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
                                hintText: "Yeni şifre oluşturun",
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
                    "Yeni Şifre (Tekrar)",
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
                        SizedBox(
                          width: 12,
                        ),
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
                                hintText: "Yeni şifrenizi tekrar edin",
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
                  // geri
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
                      child: const Text(
                        "Geri",
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
                              controller
                                  .setNewPassword(controller.newPassword.value);
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
                              child: const Text(
                                "Devam",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          )
                        : SizedBox();
                  })
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
