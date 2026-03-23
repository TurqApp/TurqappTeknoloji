part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsPhonePart on _ContactDetailsView {
  Widget _buildPhoneContactStatusRow({
    required String phone,
    required bool phoneVerified,
  }) {
    return _ContactStatusRow(
      icon: CupertinoIcons.phone,
      title: 'account_center.phone'.tr,
      value: phone.isNotEmpty ? phone : 'account_center.phone_missing'.tr,
      isVerified: phoneVerified,
      verifiedLabel: 'account_center.verified'.tr,
      pendingLabel: 'account_center.unverified'.tr,
      onTap: _handlePhoneContactTap,
    );
  }
}
