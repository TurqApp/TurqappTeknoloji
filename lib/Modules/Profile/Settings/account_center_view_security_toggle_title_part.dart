part of 'account_center_view.dart';

extension AccountCenterViewSecurityToggleTitlePart on _SessionSecuritySection {
  Widget _buildSingleDeviceTitle() {
    return Text(
      'account_center.single_device_title'.tr,
      style: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
