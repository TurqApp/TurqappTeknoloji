part of 'account_center_view.dart';

extension AccountCenterViewBodyContentPart on AccountCenterView {
  Widget _buildBodyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final items = accountCenter.accounts.toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'account_center.header_title'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'account_center.accounts'.tr,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAccountsCard(context, items),
              ],
            ),
            const SizedBox(height: 18),
            _SessionSecuritySection(
              accountCenter: accountCenter,
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: _buildPersonalDetailsSectionLabel(),
                ),
                _PersonalDetailsSection(
                  currentUserService: _currentUserService,
                  userRepository: _userRepository,
                  onContactTap: () => Get.to(() => const _ContactDetailsView()),
                ),
              ],
            ),
            if (!_isLoggedIn) const SizedBox(height: 0),
          ],
        );
      }),
    );
  }
}
