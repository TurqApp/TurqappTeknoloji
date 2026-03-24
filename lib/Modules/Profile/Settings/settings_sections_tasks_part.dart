part of 'settings.dart';

extension _SettingsViewSectionsTasksPart on _SettingsViewState {
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

  List<Widget> _buildSessionSection() {
    return [
      buildSectionTitle('settings.session'.tr),
      if (QALabMode.enabled)
        buildRow(
          'settings.diagnostics.qa_lab'.tr,
          CupertinoIcons.waveform_path_ecg,
          () => Get.to(() => const QALabView()),
          valueKey: const ValueKey(
            IntegrationTestKeys.actionSettingsOpenQaLab,
          ),
        ),
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
}
