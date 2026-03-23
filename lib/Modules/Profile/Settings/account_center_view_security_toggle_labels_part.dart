part of 'account_center_view.dart';

extension AccountCenterViewSecurityToggleLabelsPart on _SessionSecuritySection {
  Widget _buildSecurityToggleTitle() {
    return Text(
      'account_center.single_device_title'.tr,
      style: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'MontserratBold',
      ),
    );
  }

  Widget _buildSecurityToggleSubtitle() {
    return Text(
      'account_center.single_device_desc'.tr,
      style: TextStyle(
        color: Colors.black54,
        fontSize: 12,
        fontFamily: 'MontserratMedium',
        height: 1.35,
      ),
    );
  }
}
