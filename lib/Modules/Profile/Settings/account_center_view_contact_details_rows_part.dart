part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsRowsPart on _ContactDetailsView {
  Widget _buildContactDetailsRows({
    required String email,
    required String phone,
    required bool emailVerified,
    required bool phoneVerified,
  }) {
    return Column(
      children: _buildContactDetailsRowsChildren(
        email: email,
        phone: phone,
        emailVerified: emailVerified,
        phoneVerified: phoneVerified,
      ),
    );
  }
}
