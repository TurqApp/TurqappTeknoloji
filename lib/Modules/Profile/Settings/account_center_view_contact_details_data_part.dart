part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsDataPart on _ContactDetailsView {
  String _emailValue(CurrentUserService currentUserService) {
    return currentUserService.email.trim();
  }

  String _phoneValue(CurrentUserService currentUserService) {
    return currentUserService.phoneNumber.trim();
  }
}
