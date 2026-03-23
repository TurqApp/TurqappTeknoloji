part of 'account_center_view.dart';

extension AccountCenterViewSecurityHeaderPart on _SessionSecuritySection {
  Widget _buildSecurityHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        'account_center.security'.tr,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
