part of 'account_center_view.dart';

extension AccountCenterViewRemovePart on AccountCenterView {
  Future<void> _confirmRemoveAccount(
    BuildContext context,
    StoredAccount account,
  ) async {
    if (_handleRemoveActiveAccountGuard(account: account)) {
      return;
    }

    final shouldRemove = await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => _RemoveAccountDialog(
            account: account,
          ),
        ) ??
        false;

    if (!shouldRemove) return;
    await _removeAccount(account);
  }
}
