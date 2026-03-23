part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsRowsChildrenPart
    on _ContactDetailsView {
  List<Widget> _buildContactDetailsRowsChildren({
    required String email,
    required String phone,
    required bool emailVerified,
    required bool phoneVerified,
  }) {
    return [
      _buildEmailContactStatusRow(
        email: email,
        emailVerified: emailVerified,
      ),
      _buildContactDetailsDivider(),
      _buildPhoneContactStatusRow(
        phone: phone,
        phoneVerified: phoneVerified,
      ),
    ];
  }
}
