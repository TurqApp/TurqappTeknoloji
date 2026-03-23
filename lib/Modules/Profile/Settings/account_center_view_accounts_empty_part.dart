part of 'account_center_view.dart';

extension AccountCenterViewAccountsEmptyPart on AccountCenterView {
  Widget _buildAccountsEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),
      child: Text(
        'account_center.no_accounts'.tr,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
        ),
      ),
    );
  }
}
