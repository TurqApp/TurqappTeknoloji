part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsEmailPart on _ContactDetailsView {
  Widget _buildEmailContactStatusRow({
    required String email,
    required bool emailVerified,
  }) {
    return _ContactStatusRow(
      icon: CupertinoIcons.mail,
      title: 'account_center.email'.tr,
      value: email.isNotEmpty ? email : 'account_center.email_missing'.tr,
      isVerified: emailVerified,
      verifiedLabel: 'account_center.verified'.tr,
      pendingLabel: 'account_center.verify'.tr,
      onTap: () => _handleEmailContactTap(),
    );
  }
}
