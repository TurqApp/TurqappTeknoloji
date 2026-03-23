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
      await _continueWithPasswordProviderAccount(account);
      return;
    }

    if (currentUid.isNotEmpty) {
      await _clearCurrentSession(currentUid);
    }

    await _continueWithUsernameAccount(account);
  }
}
