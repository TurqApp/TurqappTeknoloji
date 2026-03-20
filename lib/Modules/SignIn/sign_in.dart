import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Profile/Policies/policies.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';

import '../../Core/Helpers/custom_nickname_formatter.dart';

part 'sign_in_auth_part.dart';
part 'sign_in_signup_part.dart';

class SignIn extends StatelessWidget {
  SignIn({
    super.key,
    this.initialIdentifier = '',
    this.storedAccountUid = '',
  }) : controller = _createFreshController() {
    controller.prepareSignInPrefill(initialIdentifier);
    controller.prepareStoredAccountContext(storedAccountUid);
  }

  final String initialIdentifier;
  final String storedAccountUid;

  final SignInController controller;

  static SignInController _createFreshController() {
    final tag = 'sign_in_${DateTime.now().microsecondsSinceEpoch}';
    return Get.put(SignInController(), tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                  createNewPassword(),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _openPolicyCenter({String? initialPolicyId}) {
    Get.to(() => Policies(initialPolicyId: initialPolicyId));
  }

  TextSpan _policyCenterTextSpan(String label) {
    return TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.black,
        decoration: TextDecoration.underline,
        fontSize: 12,
        fontFamily: 'MontserratBold',
      ),
      recognizer: TapGestureRecognizer()..onTap = () => _openPolicyCenter(),
    );
  }
}
