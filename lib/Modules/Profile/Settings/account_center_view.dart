import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email.dart';
import 'package:turqappv2/Modules/Profile/EditorPhoneNumber/editor_phone_number.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'account_center_view_actions_part.dart';
part 'account_center_view_empty_text_part.dart';
part 'account_center_view_body_part.dart';
part 'account_center_view_body_content_part.dart';
part 'account_center_view_card_shell_part.dart';

class AccountCenterView extends StatelessWidget {
  AccountCenterView({super.key});

  final AccountCenterService accountCenter = AccountCenterService.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final SignInController _signInController = SignInController();
  final Future<void> _initFuture = AccountCenterService.ensure().init();

  bool get _isLoggedIn => _currentUid.isNotEmpty;

  CurrentUserService get _currentUserService => CurrentUserService.instance;

  String get _currentUid => _currentUserService.effectiveUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>(IntegrationTestKeys.screenAccountCenter),
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'settings.account_center'.tr),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }
}
