part of 'account_center_view.dart';

extension AccountCenterViewSecurityStreamPart on _SessionSecuritySection {
  Widget _buildSecurityStream(String uid) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: UserRepository.ensure().watchUserRaw(uid),
      builder: (context, snapshot) {
        final enabled =
            (snapshot.data?['singleDeviceSessionEnabled'] ?? false) == true;
        return _buildSecurityToggle(enabled);
      },
    );
  }
}
