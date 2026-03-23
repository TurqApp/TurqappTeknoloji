part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsStatePart on _ContactDetailsView {
  Widget _buildResolvedContactDetails(CurrentUserService currentUserService) {
    final email = _emailValue(currentUserService);
    final phone = _phoneValue(currentUserService);
    final emailVerified = currentUserService.emailVerifiedRx.value;
    final phoneVerified = phone.isNotEmpty;
    return _buildAccountCenterCard(
      child: Column(
        children: [
          _buildEmailContactStatusRow(
            email: email,
            emailVerified: emailVerified,
          ),
          const Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
          ),
          _buildPhoneContactStatusRow(
            phone: phone,
            phoneVerified: phoneVerified,
          ),
        ],
      ),
    );
  }
}
