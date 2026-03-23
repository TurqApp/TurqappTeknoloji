part of 'account_center_view.dart';

extension AccountCenterViewPersonalDetailsPart on AccountCenterView {
  Widget _buildPersonalDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            'account_center.personal_details'.tr,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
        _PersonalDetailsSection(
          currentUserService: _currentUserService,
          userRepository: _userRepository,
          onContactTap: () => Get.to(() => const _ContactDetailsView()),
        ),
      ],
    );
  }
}
