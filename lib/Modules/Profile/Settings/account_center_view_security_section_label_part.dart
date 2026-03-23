part of 'account_center_view.dart';

extension AccountCenterViewSecuritySectionLabelPart on _SessionSecuritySection {
  Widget _buildSecuritySectionLabel() {
    return Text(
      'account_center.security'.tr,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
