part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsEmailActionPart
    on _ContactDetailsView {
  void _handleEmailContactTap() {
    Get.to(() => EditorEmail());
  }
}
