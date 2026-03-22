// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/Settings.dart';

extension _SettingsViewSectionsPart on _SettingsViewState {
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

  Widget _buildAssignedTasksSection() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _adminTaskAssignmentRepository.watchAssignment(
        userService.effectiveUserId,
      ),
      builder: (context, taskSnap) {
        final data = taskSnap.data?.data();
        final taskIds = normalizeAdminTaskIds(
          data?['taskIds'] is List ? data!['taskIds'] as List : const [],
        );
        if (taskIds.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            buildSectionTitle('settings.my_tasks'.tr),
            ..._buildAssignedTaskRows(taskIds),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _adminApprovalRepository.watchOwnApprovals(
                userService.effectiveUserId,
              ),
              builder: (context, approvalsSnap) {
                final docs = approvalsSnap.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                return buildRow(
                  'settings.my_approval_results'.tr,
                  CupertinoIcons.checkmark_alt_circle,
                  () => Get.to(() => const MyAdminApprovalResultsView()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminSection() {
    return FutureBuilder<bool>(
      future: AdminAccessService.isPrimaryAdmin(),
      builder: (context, adminSnap) {
        if (adminSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (adminSnap.data != true) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            buildSectionTitle('settings.system_diagnostics'.tr),
            buildRow(
              'settings.admin_ads'.tr,
              CupertinoIcons.volume_up,
              () => Get.to(() => const AdsCenterHomeView()),
            ),
            buildRow(
              'settings.admin_moderation'.tr,
              CupertinoIcons.flag_fill,
              () => Get.to(() => const ModerationSettingsView()),
            ),
            buildRow(
              'settings.admin_reports'.tr,
              CupertinoIcons.exclamationmark_bubble_fill,
              () => Get.to(() => const ReportsAdminView()),
            ),
            buildRow(
              'settings.admin_badges'.tr,
              CupertinoIcons.checkmark_seal_fill,
              () => Get.to(() => const BadgeAdminView()),
            ),
            buildRow(
              'settings.admin_tasks'.tr,
              CupertinoIcons.checkmark_rectangle_fill,
              () => Get.to(() => const AdminTaskAssignmentsView()),
            ),
            buildRow(
              'settings.admin_approvals'.tr,
              CupertinoIcons.checkmark_alt_circle_fill,
              () => Get.to(() => const AdminApprovalsView()),
            ),
            buildRow(
              'settings.admin_story_music'.tr,
              CupertinoIcons.music_note_list,
              () => Get.to(() => const StoryMusicAdminView()),
            ),
            buildRow(
              'settings.admin_support'.tr,
              CupertinoIcons.chat_bubble_2_fill,
              () => Get.to(() => const SupportAdminView()),
            ),
            buildRow(
              'settings.system_diag_menu'.tr,
              CupertinoIcons.antenna_radiowaves_left_right,
              _showSystemDiagnosticsMenu,
            ),
            _AdminPushMenuTile(buildRow: buildRow),
          ],
        );
      },
    );
  }

  List<Widget> _buildSessionSection() {
    return [
      buildSectionTitle('settings.session'.tr),
      buildRow(
        'settings.sign_out'.tr,
        CupertinoIcons.square_arrow_right,
        _showSignOutDialog,
        valueKey: const ValueKey(IntegrationTestKeys.actionSettingsSignOut),
      ),
    ];
  }

  void _showSignOutDialog() {
    noYesAlert(
      title: 'settings.sign_out_title'.tr,
      message: 'settings.sign_out_message'.tr,
      onYesPressed: () async {
        final currentUser = userService.effectiveUserId.trim();
        if (currentUser.isNotEmpty) {
          await _userRepository.updateUserFields(
            currentUser,
            {"token": ""},
          );
          await AccountCenterService.ensure().markSessionState(
            uid: currentUser,
            isSessionValid: false,
          );
        }

        try {
          await CurrentUserService.instance.logout();
          await FirebaseAuth.instance.signOut();
          await Get.offAll(() => SignIn());
        } catch (e) {
          print("Sign out failed: $e");
        }
      },
      yesText: "settings.sign_out_title".tr,
      cancelText: "common.cancel".tr,
    );
  }

  List<Widget> _buildAssignedTaskRows(List<String> taskIds) {
    final rows = <Widget>[];
    final seen = <String>{};
    for (final taskId in taskIds) {
      if (!seen.add(taskId)) continue;
      final task = adminTaskCatalogById[taskId];
      if (task == null) continue;
      rows.add(
        buildRow(task.titleKey.tr, task.icon, () => _openAssignedTask(taskId)),
      );
    }
    return rows;
  }

  void _openAssignedTask(String taskId) {
    switch (taskId) {
      case 'moderation':
      case 'user_bans':
        Get.to(() => const ModerationSettingsView());
        return;
      case 'reports':
        Get.to(() => const ReportsAdminView());
        return;
      case 'badges':
        Get.to(() => const BadgeAdminView());
        return;
      case 'approvals':
        Get.to(() => const AdminApprovalsView());
        return;
      case 'admin_push':
        Get.to(() => const AdminPushView());
        return;
      case 'ads_center':
        Get.to(() => const AdsCenterHomeView());
        return;
      case 'story_music':
        Get.to(() => const StoryMusicAdminView());
        return;
      case 'pasaj':
        Get.to(() => PasajSettingsView());
        return;
      case 'support':
        Get.to(() => const SupportAdminView());
        return;
    }
  }
}
