part of 'account_center_view.dart';

extension AccountCenterViewBodyPart on AccountCenterView {
  Widget _buildBody(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(() {
            final items = accountCenter.accounts.toList(growable: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAccountsSection(context, items),
                const SizedBox(height: 18),
                _SessionSecuritySection(
                  accountCenter: accountCenter,
                ),
                const SizedBox(height: 18),
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
                if (!_isLoggedIn) const SizedBox(height: 0),
              ],
            );
          }),
        );
      },
    );
  }
}
