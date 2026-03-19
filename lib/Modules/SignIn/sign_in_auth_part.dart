part of 'sign_in.dart';

extension SignInAuthPart on SignIn {
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
                      children: const [
                        Text(
                          'Cihazdaki hesaplar',
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
                                        ? 'Son kullanilan'
                                        : 'Kayitli hesap',
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
          GestureDetector(
            onTap: () {
              controller.clearStoredAccountContext();
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.2,
                  fontFamily: 'Montserrat',
                ),
                children: [
                  _policyCenterTextSpan('Sözleşme ve politikaları incele')
                ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
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
          Obx(() {
            final account = controller.selectedStoredAccount.value;
            if (account == null) return const SizedBox.shrink();
            String message;
            switch (account.primaryProvider) {
              case 'phone':
                message =
                    '@${account.username} telefon ile kayitli gorunuyor. Bu hesap icin manuel yeniden giris yapman gerekiyor.';
                break;
              case 'password':
                message =
                    '@${account.username} secildi. Giris bilgilerini tamamlayip devam edebilirsin.';
                break;
              default:
                message =
                    '@${account.username} icin manuel yeniden giris yapman gerekiyor.';
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
                        SizedBox(width: 12),
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
                              controller.clearStoredAccountContext();
                              controller.selection.value = 5;
                            },
                            child: Text(
                              "Sıfırla",
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
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.2,
                  fontFamily: 'Montserrat',
                ),
                children: [
                  _policyCenterTextSpan('Sözleşme ve politikaları incele')
                ],
              ),
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
                          AppSnackbar(
                            'Eksik Bilgi',
                            'Kullanıcı adı/e-posta ve şifre girin.',
                          );
                          return;
                        }
                        if (pass.length < 6) {
                          AppSnackbar(
                            'Hatalı Şifre',
                            'Şifre en az 6 karakter olmalı.',
                          );
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
          SizedBox(height: 12),
          Text(
            "Mail adresinizi girerek hesabınızı bulmamızda yardımcı olun. Hesabınızda kayıt olan telefon numaranıza bir doğrulama kodu göndereceğiz",
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
              SizedBox(height: 12),
              Text(
                "En az bir karakteri büyük olmalı ve en az 6 karakterden oluşmalıdır.",
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
