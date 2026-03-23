part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsCardPart on _ContactDetailsView {
  Widget _buildContactDetailsCard({
    required String email,
    required String phone,
    required bool emailVerified,
    required bool phoneVerified,
  }) {
    return _buildAccountCenterCard(
      child: _buildContactDetailsRows(
        email: email,
        phone: phone,
        emailVerified: emailVerified,
        phoneVerified: phoneVerified,
      ),
    );
  }
}
