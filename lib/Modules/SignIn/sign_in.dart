import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Profile/Policies/policies.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';

import '../../Core/Helpers/custom_nickname_formatter.dart';

part 'sign_in_auth_part.dart';
part 'sign_in_start_part.dart';
part 'sign_in_signin_part.dart';
part 'sign_in_password_reset_part.dart';
part 'sign_in_signup_part.dart';
part 'sign_in_signup_identity_part.dart';
part 'sign_in_signup_profile_part.dart';
part 'sign_in_signup_otp_part.dart';

class SignIn extends StatefulWidget {
  const SignIn({
    super.key,
    this.initialIdentifier = '',
    this.storedAccountUid = '',
  });

  final String initialIdentifier;
  final String storedAccountUid;

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late final SignInController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'sign_in_${identityHashCode(this)}';
    controller = SignInController.ensure(tag: _controllerTag);
    controller.prepareSignInPrefill(widget.initialIdentifier);
    controller.prepareStoredAccountContext(widget.storedAccountUid);
  }

  @override
  void dispose() {
    final existing = SignInController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<SignInController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenSignIn),
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
