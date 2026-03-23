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
}
