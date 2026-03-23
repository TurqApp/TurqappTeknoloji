part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsCardBodyPart on _ContactDetailsView {
  Widget _buildContactDetailsCardBody({
    required String email,
    required String phone,
    required bool emailVerified,
    required bool phoneVerified,
  }) {
    return Container(
      decoration: _buildContactDetailsCardDecoration(),
      child: _buildContactDetailsRows(
        email: email,
        phone: phone,
        emailVerified: emailVerified,
        phoneVerified: phoneVerified,
      ),
    );
  }
}
