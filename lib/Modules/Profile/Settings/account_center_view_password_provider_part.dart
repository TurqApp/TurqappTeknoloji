part of 'account_center_view.dart';

extension AccountCenterViewPasswordProviderPart on AccountCenterView {
  Future<void> _continueWithPasswordProviderAccount(
    StoredAccount account,
  ) async {
    final switched = await _continueWithPasswordAccount(account);
    if (switched) {
      return;
    }
    if (!account.requiresReauth) {
      AppSnackbar(
        'account_center.switch_failed_title'.tr,
        'account_center.switch_failed_body'.tr,
      );
    }
  }
}
