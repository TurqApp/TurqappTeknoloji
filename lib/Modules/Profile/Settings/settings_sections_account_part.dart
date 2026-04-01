part of 'settings.dart';

extension _SettingsViewSectionsAccountPart on _SettingsViewState {
  List<Widget> _buildPrimarySections() {
    return [
      buildSectionTitle('settings.account'.tr),
      buildRow(
        'settings.edit_profile'.tr,
        CupertinoIcons.pencil_outline,
        () => Get.to(() => EditProfile()),
      ),
      _buildVerifiedAccountRow(),
      buildRow(
        'settings.blocked_users'.tr,
        CupertinoIcons.exclamationmark_circle,
        () => Get.to(() => BlockedUsers()),
      ),
      buildRow(
        'settings.interests'.tr,
        CupertinoIcons.sparkles,
        () => Get.to(() => Interests()),
      ),
      buildRow(
        'settings.account_center'.tr,
        CupertinoIcons.person_2_square_stack,
        () => Get.to(() => AccountCenterView()),
        valueKey:
            const ValueKey(IntegrationTestKeys.actionSettingsOpenAccountCenter),
      ),
      buildRow(
        'settings.career_profile'.tr,
        CupertinoIcons.paperclip,
        () => Get.to(() => Cv()),
      ),
      buildSectionTitle('settings.content'.tr),
      buildRow(
        'settings.saved_posts'.tr,
        CupertinoIcons.bookmark,
        () => Get.to(() => SavedPosts()),
      ),
      buildRow(
        'settings.archive'.tr,
        CupertinoIcons.refresh_thick,
        () => Get.to(() => Archives()),
      ),
      buildRow(
        'settings.liked_posts'.tr,
        CupertinoIcons.hand_thumbsup,
        () => Get.to(() => LikedPosts()),
      ),
      buildSectionTitle('settings.app'.tr),
      buildRow(
        'settings.language'.tr,
        CupertinoIcons.globe,
        () => Get.to(() => const LanguageSettingsView()),
        showLanguageLabel: true,
      ),
      buildRow(
        'settings.notifications'.tr,
        CupertinoIcons.bell,
        () => Get.to(() => const NotificationSettingsView()),
      ),
      buildRow(
        'settings.permissions'.tr,
        CupertinoIcons.lock_shield,
        () => Get.to(() => const PermissionsView()),
        valueKey:
            const ValueKey(IntegrationTestKeys.actionSettingsOpenPermissions),
      ),
      buildRow(
        'settings.pasaj'.tr,
        CupertinoIcons.nosign,
        () => Get.to(() => PasajSettingsView()),
        usePasajIcon: true,
      ),
      buildSectionTitle('settings.security_support'.tr),
      buildRow(
        'settings.about'.tr,
        CupertinoIcons.info,
        () => Get.to(
          () => AboutProfile(
            userID: userService.effectiveUserId,
          ),
        ),
      ),
      buildRow(
        'settings.policies'.tr,
        CupertinoIcons.shield,
        () => Get.to(() => Policies()),
      ),
      buildRow(
        'settings.contact_us'.tr,
        CupertinoIcons.pencil_circle,
        () => Get.to(() => const SupportContactView()),
      ),
    ];
  }

  Widget _buildVerifiedAccountRow() {
    return FutureBuilder<VerifiedAccountApplicationState?>(
      future: _verifiedAccountRepository.fetchApplicationState(
        userService.effectiveUserId,
      ),
      builder: (context, snapshot) {
        final application = snapshot.data;
        final hasPendingApplication = application?.isPending == true;
        final canRenew = application?.canSubmitRenewal == true;
        final hasBadge = userService.rozet.isNotEmpty;
        if (hasPendingApplication) {
          return buildRow(
            'settings.badge_application'.tr,
            CupertinoIcons.doc_text_search,
            () => Get.to(() => BecomeVerifiedAccount()),
          );
        }
        if (canRenew) {
          return buildRow(
            'settings.badge_renew'.tr,
            CupertinoIcons.arrow_clockwise_circle,
            () => Get.to(() => BecomeVerifiedAccount()),
          );
        }
        if (!hasBadge) {
          return buildRow(
            'settings.become_verified'.tr,
            CupertinoIcons.checkmark_seal,
            () => Get.to(() => BecomeVerifiedAccount()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
