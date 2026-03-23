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
        _buildContactDetailsDivider(),
        _buildPhoneContactStatusRow(
          phone: phone,
          phoneVerified: phoneVerified,
        ),
      ],
    );
  }
}
