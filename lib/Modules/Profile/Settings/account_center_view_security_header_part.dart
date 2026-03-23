part of 'account_center_view.dart';

extension AccountCenterViewSecurityHeaderPart on _SessionSecuritySection {
  Widget _buildSecurityHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: _buildSecuritySectionLabel(),
    );
  }
}
