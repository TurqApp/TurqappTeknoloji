part of 'account_center_view.dart';

extension AccountCenterViewActionsPart on AccountCenterView {
  Future<void> _continueWithAccount(StoredAccount account) async {
    final currentUid = _currentUid;
    if (currentUid == account.uid) {
      AppSnackbar(
        'account_center.active_account_title'.tr,
        'account_center.active_account_body'
            .trParams(<String, String>{'username': account.username}),
      );
      return;
    }

    if (account.hasPasswordProvider) {
      if (account.requiresReauth) {
        final identifier = await _signInController
            .preferredIdentifierForStoredAccount(account);
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
        return;
      }
      Get.dialog(
        const Center(child: CupertinoActivityIndicator()),
        barrierDismissible: false,
      );
      final switched = await _signInController.signInWithStoredAccount(account);
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      if (switched) return;
      AppSnackbar(
        'account_center.switch_failed_title'.tr,
        'account_center.switch_failed_body'.tr,
      );
      return;
    }

    if (currentUid.isNotEmpty) {
      await _clearCurrentSession(currentUid);
    }

    await Get.offAll(
      () => SignIn(
        initialIdentifier: account.username,
        storedAccountUid: account.uid,
      ),
    );
  }
}
