part of 'account_center_view.dart';

extension AccountCenterViewRemoveDialogActionsPart on _RemoveAccountDialog {
  List<Widget> _buildRemoveAccountDialogActions(BuildContext context) {
    return [
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text('common.cancel'.tr),
      ),
      CupertinoDialogAction(
        isDestructiveAction: true,
        onPressed: () => Navigator.of(context).pop(true),
        child: Text('common.delete'.tr),
      ),
    ];
  }
}
