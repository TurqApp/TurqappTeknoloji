part of 'account_center_view.dart';

extension AccountCenterViewAccountsAddPart on AccountCenterView {
  Widget _buildAddAccountAction() {
    return InkWell(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(18),
      ),
      onTap: () => Get.to(() => SignIn()),
      child: _buildAddAccountActionBody(),
    );
  }
}
