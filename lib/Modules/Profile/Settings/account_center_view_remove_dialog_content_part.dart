part of 'account_center_view.dart';

class _RemoveAccountDialog extends StatelessWidget {
  const _RemoveAccountDialog({
    required this.account,
  });

  final StoredAccount account;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text('account_center.remove_account_title'.tr),
      content: Text(
        'account_center.remove_account_body'
            .trParams(<String, String>{'username': account.username}),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('common.cancel'.tr),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('common.delete'.tr),
        ),
      ],
    );
  }
}
