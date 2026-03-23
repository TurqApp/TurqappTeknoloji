part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsRowsPart on _ContactDetailsView {
  Widget _buildContactDetailsRows({
    required String email,
    required String phone,
    required bool emailVerified,
    required bool phoneVerified,
  }) {
    return Column(
      children: [
        _buildEmailContactStatusRow(
          email: email,
          emailVerified: emailVerified,
        ),
        const Divider(height: 1, indent: 18, endIndent: 18),
        _buildPhoneContactStatusRow(
          phone: phone,
          phoneVerified: phoneVerified,
        ),
      ],
    );
  }
}
