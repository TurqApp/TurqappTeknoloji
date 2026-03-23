part of 'account_center_view.dart';

extension AccountCenterViewPasswordSwitchPart on AccountCenterView {
  Future<bool> _continueWithPasswordAccount(StoredAccount account) async {
    if (account.requiresReauth) {
      return _continueWithReauthAccount(account);
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
