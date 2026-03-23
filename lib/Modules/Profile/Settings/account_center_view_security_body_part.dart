part of 'account_center_view.dart';

extension AccountCenterViewSecurityBodyPart on _SessionSecuritySection {
  Widget _buildSecuritySectionBody(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSecurityHeader(),
        _buildSecurityContent(uid),
      ],
    );
  }
}
