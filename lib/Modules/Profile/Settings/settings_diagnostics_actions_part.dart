// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/settings.dart';

extension _SettingsViewDiagnosticsActionsPart on _SettingsViewState {
  void _showQuickActions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Wrap(
            children: [
              ListTile(
                title: Text(
                  "settings.diagnostics.quick_actions".tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_counterclockwise),
                title: Text("settings.diagnostics.reset_data_counters".tr),
                onTap: () async {
                  Get.back();
                  await _settingsNetworkRuntimeService.resetDataUsage();
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.data_counters_reset".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.refresh_circled),
                title: Text("settings.diagnostics.sync_offline_queue_now".tr),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.processPendingNow(
                    ignoreBackoff: true,
                  );
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.offline_queue_sync_triggered".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_2_circlepath_circle),
                title: Text("settings.diagnostics.retry_dead_letter".tr),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.retryDeadLetter();
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.dead_letter_queued".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.clear_circled),
                title: Text("settings.diagnostics.clear_dead_letter".tr),
                onTap: () async {
                  Get.back();
                  await OfflineModeService.instance.clearDeadLetter();
                  AppSnackbar("common.success".tr,
                      "settings.diagnostics.dead_letter_cleared".tr);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.pause_circle),
                title: Text("settings.diagnostics.pause_prefetch".tr),
                onTap: () {
                  Get.back();
                  final prefetch = maybeFindPrefetchScheduler();
                  if (prefetch != null) {
                    prefetch.pause();
                    AppSnackbar("common.success".tr,
                        "settings.diagnostics.prefetch_paused".tr);
                  } else {
                    AppSnackbar("common.info".tr,
                        "settings.diagnostics.service_not_ready".tr);
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.play_circle),
                title: Text("settings.diagnostics.resume_prefetch".tr),
                onTap: () {
                  Get.back();
                  final prefetch = maybeFindPrefetchScheduler();
                  if (prefetch != null) {
                    prefetch.resume();
                    AppSnackbar("common.success".tr,
                        "settings.diagnostics.prefetch_resumed".tr);
                  } else {
                    AppSnackbar("common.info".tr,
                        "settings.diagnostics.service_not_ready".tr);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
