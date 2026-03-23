part of 'account_center_view.dart';

extension AccountCenterViewPersonalHeaderPart on AccountCenterView {
  Widget _buildPersonalDetailsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        'account_center.personal_details'.tr,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
