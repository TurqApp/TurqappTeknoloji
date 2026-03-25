// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/settings.dart';

extension _SettingsViewSectionsAdminPart on _SettingsViewState {
  Widget _buildAdminSection() {
    return FutureBuilder<bool>(
      future: AdminAccessService.canManageSliders(),
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
            buildRow(
              'settings.diagnostics.qa_lab'.tr,
              CupertinoIcons.waveform_path_ecg,
              () => Get.to(() => const QALabView()),
            ),
            _AdminPushMenuTile(buildRow: buildRow),
          ],
        );
      },
    );
  }
}

class _AdminPushMenuTile extends StatefulWidget {
  const _AdminPushMenuTile({required this.buildRow});

  final Widget Function(String, IconData, VoidCallback, {bool isNew}) buildRow;

  @override
  State<_AdminPushMenuTile> createState() => _AdminPushMenuTileState();
}

class _AdminPushMenuTileState extends State<_AdminPushMenuTile> {
  late final Future<bool> _canShowFuture;

  Future<bool> _canShowAdminPushMenu() async {
    if (CurrentUserService.instance.effectiveUserId.isEmpty) return false;

    final isAdmin = await AdminAccessService.canManageSliders();
    if (!isAdmin) return false;

    final data = await ConfigRepository.ensure().getAdminConfigDoc(
          'admin',
          preferCache: true,
        ) ??
        <String, dynamic>{};
    return data["pushSend"] == true;
  }

  @override
  void initState() {
    super.initState();
    _canShowFuture = _canShowAdminPushMenu();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canShowFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return widget.buildRow(
          "settings.admin_push".tr,
          CupertinoIcons.paperplane,
          () => Get.to(() => const AdminPushView()),
        );
      },
    );
  }
}
