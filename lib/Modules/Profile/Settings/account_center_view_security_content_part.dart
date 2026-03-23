part of 'account_center_view.dart';

extension AccountCenterViewSecurityContentPart on _SessionSecuritySection {
  Widget _buildSecurityContent(String uid) {
    return Container(
      decoration: _buildAccountCenterCardDecoration(),
      child: _buildSecurityStream(uid),
    );
  }
}
