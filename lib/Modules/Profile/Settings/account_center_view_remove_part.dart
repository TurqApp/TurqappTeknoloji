part of 'account_center_view.dart';

extension AccountCenterViewRemovePart on AccountCenterView {
  Future<void> _confirmRemoveAccount(
    BuildContext context,
    StoredAccount account,
  ) async {
    final currentUid = _currentUid;
    if (currentUid == account.uid) {
      AppSnackbar(
        'account_center.active_account_title'.tr,
        'account_center.remove_active_forbidden'.tr,
      );
      return;
    }

    final shouldRemove = await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text('account_center.remove_account_title'.tr),
            content: Text(
              'account_center.remove_account_body'
                  .trParams(<String, String>{'username': account.username}),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('common.cancel'.tr),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('common.delete'.tr),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRemove) return;
    await accountCenter.removeAccount(account.uid);
    AppSnackbar(
      'common.success'.tr,
      'account_center.account_removed'
          .trParams(<String, String>{'username': account.username}),
    );
  }
}
