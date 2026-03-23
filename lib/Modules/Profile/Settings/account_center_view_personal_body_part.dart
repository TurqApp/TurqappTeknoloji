part of 'account_center_view.dart';

extension AccountCenterViewPersonalBodyPart on AccountCenterView {
  Widget _buildPersonalDetailsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPersonalDetailsHeader(),
        _PersonalDetailsSection(
          currentUserService: _currentUserService,
          userRepository: _userRepository,
          onContactTap: () => Get.to(() => const _ContactDetailsView()),
        ),
      ],
    );
  }
}
