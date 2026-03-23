part of 'account_center_view.dart';

extension AccountCenterViewRemoveExecutePart on AccountCenterView {
  Future<void> _removeAccount(StoredAccount account) async {
    await accountCenter.removeAccount(account.uid);
    AppSnackbar(
      'common.success'.tr,
      'account_center.account_removed'
          .trParams(<String, String>{'username': account.username}),
    );
  }
}
