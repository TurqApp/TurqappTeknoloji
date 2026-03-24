// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/settings.dart';

extension _SettingsViewDiagnosticsMenuPart on _SettingsViewState {
  void _showVideoCacheDetails() {
    final cache = SegmentCacheManager.maybeFind();
    final prefetch = PrefetchScheduler.maybeFind();

    final metrics = cache?.metrics.toJson() ?? {};
    final hitRate = (metrics['cacheHitRate'] ?? '0.0%').toString();

    Get.dialog(
      AlertDialog(
        title: Text("settings.diagnostics.video_cache_detail".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${'settings.diagnostics.saved_videos'.tr}: ${cache?.entryCount ?? 0}"),
            Text(
                "${'settings.diagnostics.saved_segments'.tr}: ${cache?.totalSegmentCount ?? 0}"),
            Text(
              "${'settings.diagnostics.disk_usage'.tr}: ${cache == null ? 'settings.diagnostics.unknown'.tr : CacheMetrics.formatBytes(cache.totalSizeBytes)}",
            ),
            const SizedBox(height: 8),
            Text("settings.diagnostics.cache_traffic".tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${'settings.diagnostics.hit_rate'.tr}: $hitRate"),
            Text(
                "${'settings.diagnostics.hit'.tr}: ${metrics['cacheHits'] ?? 0}"),
            Text(
                "${'settings.diagnostics.miss'.tr}: ${metrics['cacheMisses'] ?? 0}"),
            Text(
                "${'settings.diagnostics.cache_served'.tr}: ${metrics['bytesServedFromCache'] ?? '0B'}"),
            Text(
                "${'settings.diagnostics.downloaded_from_network'.tr}: ${metrics['bytesDownloaded'] ?? '0B'}"),
            const SizedBox(height: 8),
            Text("settings.diagnostics.prefetch".tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
                "${'settings.diagnostics.queue'.tr}: ${prefetch?.queueSize ?? 0}"),
            Text(
                "${'settings.diagnostics.active_downloads'.tr}: ${prefetch?.activeDownloads ?? 0}"),
            Text(
                "${'settings.diagnostics.status'.tr}: ${(prefetch?.isPaused ?? true) ? 'settings.diagnostics.paused'.tr : 'settings.diagnostics.active'.tr}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
          ),
        ],
      ),
    );
  }

  void _showSystemDiagnosticsMenu() {
    _ensureDiagnosticsServices();
    UserAnalyticsService.instance.trackFeatureUsage('diagnostics_menu_open');

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
                  "settings.system_diag_menu".tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading:
                    const Icon(CupertinoIcons.antenna_radiowaves_left_right),
                title: Text("settings.diagnostics.data_usage".tr),
                onTap: () {
                  Get.back();
                  _showDataUsageDialog();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.chart_bar),
                title: Text("settings.diagnostics.app_health_panel".tr),
                onTap: () {
                  Get.back();
                  Get.to(() => const AppHealthDashboard());
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.play_rectangle),
                title: Text("settings.diagnostics.video_cache_detail".tr),
                onTap: () {
                  Get.back();
                  _showVideoCacheDetails();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.bolt_horizontal_circle),
                title: Text("settings.diagnostics.quick_actions".tr),
                onTap: () {
                  Get.back();
                  _showQuickActions();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.tray_2),
                title: Text("settings.diagnostics.offline_queue_detail".tr),
                onTap: () {
                  Get.back();
                  _showOfflineQueueDetails();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_bubble),
                title: Text("settings.diagnostics.last_error_summary".tr),
                onTap: () {
                  Get.back();
                  _showLastErrorSummary();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_triangle),
                title: Text("settings.diagnostics.error_report".tr),
                onTap: () {
                  Get.back();
                  Get.to(() => const ErrorReportWidget());
                },
              ),
              if (QALabMode.enabled)
                ListTile(
                  leading: const Icon(CupertinoIcons.waveform_path_ecg),
                  title: Text("settings.diagnostics.qa_lab".tr),
                  onTap: () {
                    Get.back();
                    Get.to(() => const QALabView());
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
