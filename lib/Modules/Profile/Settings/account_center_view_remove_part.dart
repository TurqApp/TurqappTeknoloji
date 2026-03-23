part of 'account_center_view.dart';

extension AccountCenterViewRemovePart on AccountCenterView {
  Future<void> _confirmRemoveAccount(
    BuildContext context,
    StoredAccount account,
  ) async {
    if (_handleRemoveActiveAccountGuard(account: account)) {
      return;
    }

    final shouldRemove = await _showRemoveAccountDialog(context, account);

    if (!shouldRemove) return;
    await _removeAccount(account);
  }
}
