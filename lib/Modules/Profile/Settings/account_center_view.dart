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
part 'account_center_view_sections_part.dart';

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
              child: FutureBuilder<void>(
                future: _initFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      final items =
                          accountCenter.accounts.toList(growable: false);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 4, 4, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'account_center.header_title'.tr,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 26,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                                SizedBox(height: 18),
                                Text(
                                  'account_center.accounts'.tr,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: items.isEmpty
                                ? Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 22,
                                    ),
                                    child: Text(
                                      'account_center.no_accounts'.tr,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontFamily: 'MontserratMedium',
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (var i = 0;
                                          i < items.length;
                                          i++) ...[
                                        _AccountRow(
                                          account: items[i],
                                          avatar: _avatar(items[i]),
                                          onTap: () =>
                                              _continueWithAccount(items[i]),
                                          onLongPress: () =>
                                              _confirmRemoveAccount(
                                            context,
                                            items[i],
                                          ),
                                        ),
                                        if (i != items.length - 1)
                                          const Divider(
                                            height: 1,
                                            indent: 84,
                                            endIndent: 16,
                                          ),
                                      ],
                                      InkWell(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          bottom: Radius.circular(18),
                                        ),
                                        onTap: () => Get.to(() => SignIn()),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 18,
                                          ),
                                          child: Text(
                                            'account_center.add_account'.tr,
                                            style: TextStyle(
                                              color: Color(0xFF3797EF),
                                              fontSize: 15,
                                              fontFamily: 'MontserratBold',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 18),
                          _SessionSecuritySection(
                            accountCenter: accountCenter,
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              'account_center.personal_details'.tr,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                          _PersonalDetailsSection(
                            currentUserService: _currentUserService,
                            userRepository: _userRepository,
                            onContactTap: () =>
                                Get.to(() => const _ContactDetailsView()),
                          ),
                          if (!_isLoggedIn) const SizedBox(height: 0),
                        ],
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
