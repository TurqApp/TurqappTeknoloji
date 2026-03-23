part of 'account_center_view.dart';

extension AccountCenterViewAccountsSectionLabelPart on AccountCenterView {
  Widget _buildAccountsSectionLabel() {
    return Text(
      'account_center.accounts'.tr,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
