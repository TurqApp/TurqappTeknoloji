part of 'settings.dart';

extension _SettingsViewSectionsSessionPart on _SettingsViewState {
  List<Widget> _buildSessionSection() {
    return [
      buildSectionTitle('settings.session'.tr),
      buildRow(
        'settings.sign_out'.tr,
        CupertinoIcons.square_arrow_right,
        _showSignOutDialog,
        valueKey: const ValueKey(IntegrationTestKeys.actionSettingsSignOut),
      ),
    ];
  }

  void _showSignOutDialog() {
    noYesAlert(
      title: 'settings.sign_out_title'.tr,
      message: 'settings.sign_out_message'.tr,
      onYesPressed: () async {
        final currentUser = userService.effectiveUserId.trim();
        if (currentUser.isNotEmpty) {
          await _userRepository.updateUserFields(
            currentUser,
            {"token": ""},
          );
          await AccountCenterService.ensure().markSessionState(
            uid: currentUser,
            isSessionValid: false,
          );
        }

        try {
          await CurrentUserService.instance.logout();
          await FirebaseAuth.instance.signOut();
          await Get.offAll(() => SignIn());
        } catch (e) {
          print("Sign out failed: $e");
        }
      },
      yesText: "settings.sign_out_title".tr,
      cancelText: "common.cancel".tr,
    );
  }
}
