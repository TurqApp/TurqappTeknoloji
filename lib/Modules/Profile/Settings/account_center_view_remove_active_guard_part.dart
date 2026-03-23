part of 'account_center_view.dart';

extension AccountCenterViewRemoveActiveGuardPart on AccountCenterView {
  bool _handleRemoveActiveAccountGuard({
    required StoredAccount account,
  }) {
    if (_currentUid != account.uid) {
      return false;
    }

    AppSnackbar(
      'account_center.active_account_title'.tr,
      'account_center.remove_active_forbidden'.tr,
    );
    return true;
  }
}
