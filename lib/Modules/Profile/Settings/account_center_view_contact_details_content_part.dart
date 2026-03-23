part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsContentPart on _ContactDetailsView {
  Widget _buildContactDetailsContent(CurrentUserService currentUserService) {
    return Obx(() => _buildResolvedContactDetails(currentUserService));
  }
}
