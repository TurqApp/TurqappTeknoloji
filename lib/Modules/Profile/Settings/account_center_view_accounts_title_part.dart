part of 'account_center_view.dart';

extension AccountCenterViewAccountsTitlePart on AccountCenterView {
  Widget _buildAccountsTitle() {
    return Text(
      'account_center.header_title'.tr,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 26,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
