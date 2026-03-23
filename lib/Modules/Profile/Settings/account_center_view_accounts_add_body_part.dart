part of 'account_center_view.dart';

extension AccountCenterViewAccountsAddBodyPart on AccountCenterView {
  Widget _buildAddAccountActionBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      child: Text(
        'account_center.add_account'.tr,
        style: const TextStyle(
          color: Color(0xFF3797EF),
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
