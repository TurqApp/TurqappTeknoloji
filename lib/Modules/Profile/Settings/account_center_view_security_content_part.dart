part of 'account_center_view.dart';

extension AccountCenterViewSecurityContentPart on _SessionSecuritySection {
  Widget _buildSecurityContent(String uid) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: UserRepository.ensure().watchUserRaw(uid),
        builder: (context, snapshot) {
          final enabled =
              (snapshot.data?['singleDeviceSessionEnabled'] ?? false) == true;
          return _buildSecurityToggle(enabled);
        },
      ),
    );
  }
}
