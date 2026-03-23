part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsContentPart on _ContactDetailsView {
  Widget _buildContactDetailsContent(CurrentUserService currentUserService) {
    return Obx(() {
      final email = _emailValue(currentUserService);
      final phone = _phoneValue(currentUserService);
      final emailVerified = currentUserService.emailVerifiedRx.value;
      final phoneVerified = phone.isNotEmpty;
      return _buildContactDetailsCard(
        email: email,
        phone: phone,
        emailVerified: emailVerified,
        phoneVerified: phoneVerified,
      );
    });
  }
}
