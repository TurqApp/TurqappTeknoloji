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
    return _buildSingleDeviceSubtitle();
  }
}
