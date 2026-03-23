part of 'account_center_view.dart';

extension AccountCenterViewActiveAccountPart on AccountCenterView {
  bool _handleActiveAccountGuard({
    required String currentUid,
    required StoredAccount account,
  }) {
    if (currentUid != account.uid) {
      return false;
    }

    AppSnackbar(
      'account_center.active_account_title'.tr,
      'account_center.active_account_body'
          .trParams(<String, String>{'username': account.username}),
    );
    return true;
  }
}
