part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsPhoneActionPart
    on _ContactDetailsView {
  void _handlePhoneContactTap() {
    Get.to(() => EditorPhoneNumber());
  }
}
