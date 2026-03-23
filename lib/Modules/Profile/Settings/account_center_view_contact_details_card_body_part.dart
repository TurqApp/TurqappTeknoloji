part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsCardBodyPart on _ContactDetailsView {
  Widget _buildContactDetailsCardBody({
    required String email,
    required String phone,
    required bool emailVerified,
    required bool phoneVerified,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
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
      ),
    );
  }
}
