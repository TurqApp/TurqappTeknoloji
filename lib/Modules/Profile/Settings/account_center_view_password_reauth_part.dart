part of 'account_center_view.dart';

extension AccountCenterViewPasswordReauthPart on AccountCenterView {
  Future<bool> _continueWithReauthAccount(StoredAccount account) async {
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
}
