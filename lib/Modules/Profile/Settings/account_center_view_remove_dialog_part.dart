part of 'account_center_view.dart';

extension AccountCenterViewRemoveDialogPart on AccountCenterView {
  Future<bool> _showRemoveAccountDialog(
    BuildContext context,
    StoredAccount account,
  ) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => _RemoveAccountDialog(
            account: account,
          ),
        ) ??
        false;
  }
}
