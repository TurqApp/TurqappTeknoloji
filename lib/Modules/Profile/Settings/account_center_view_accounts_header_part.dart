part of 'account_center_view.dart';

extension AccountCenterViewAccountsHeaderPart on AccountCenterView {
  Widget _buildAccountsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account_center.header_title'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'account_center.accounts'.tr,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontFamily: 'MontserratBold',
            ),
          ),
        ],
      ),
    );
  }
}
