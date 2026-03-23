part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsBodyPart on _ContactDetailsView {
  Widget _buildContactDetailsBody(CurrentUserService currentUserService) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() => _buildResolvedContactDetails(currentUserService)),
      ),
    );
  }
}
