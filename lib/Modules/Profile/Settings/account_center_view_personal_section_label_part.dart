part of 'account_center_view.dart';

extension AccountCenterViewPersonalSectionLabelPart on AccountCenterView {
  Widget _buildPersonalDetailsSectionLabel() {
    return Text(
      'account_center.personal_details'.tr,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
