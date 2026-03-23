part of 'account_center_view.dart';

extension AccountCenterViewSecurityToggleSubtitlePart
    on _SessionSecuritySection {
  Widget _buildSingleDeviceSubtitle() {
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
