part of 'account_center_view.dart';

extension AccountCenterViewAccountsAddActionPart on AccountCenterView {
  void _handleAddAccountTap() {
    Get.to(() => SignIn());
  }
}
