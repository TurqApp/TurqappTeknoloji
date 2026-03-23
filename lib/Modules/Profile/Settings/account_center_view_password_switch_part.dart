part of 'account_center_view.dart';

extension AccountCenterViewPasswordSwitchPart on AccountCenterView {
  Future<bool> _continueWithPasswordAccount(StoredAccount account) async {
    if (account.requiresReauth) {
      final identifier =
          await _signInController.preferredIdentifierForStoredAccount(account);
      await Get.offAll(
        () => SignIn(
          initialIdentifier: identifier,
          storedAccountUid: account.uid,
        ),
      );
      AppSnackbar(
        'account_center.reauth_title'.tr,
        'account_center.reauth_body'
            .trParams(<String, String>{'username': account.username}),
      );
      return true;
    }

    Get.dialog(
      const Center(child: CupertinoActivityIndicator()),
      barrierDismissible: false,
    );
    final switched = await _signInController.signInWithStoredAccount(account);
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    return switched;
  }
}
