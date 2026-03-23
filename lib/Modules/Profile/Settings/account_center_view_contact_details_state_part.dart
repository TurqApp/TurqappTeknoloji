part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsStatePart on _ContactDetailsView {
  Widget _buildResolvedContactDetails(CurrentUserService currentUserService) {
    final email = _emailValue(currentUserService);
    final phone = _phoneValue(currentUserService);
    final emailVerified = currentUserService.emailVerifiedRx.value;
    final phoneVerified = phone.isNotEmpty;
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
