// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/Settings.dart';

extension _SettingsViewDiagnosticsPart on _SettingsViewState {
  void _showDataUsageDialog() {
    final networkService = NetworkAwarenessService.ensure();
    final stats = networkService.getNetworkStats();
    final usage = networkService.dataUsage;
    final now = DateTime.now();
    final resetStart = usage.lastReset;
    final resetHours =
        (now.difference(resetStart).inMinutes / 60).clamp(1.0, 99999.0);
    final monthlyTotalMB = (stats['monthlyUsageMB'] as num?)?.toDouble() ?? 0.0;
    final monthlyAvgPerHour = monthlyTotalMB / resetHours;
    final cacheManager = SegmentCacheManager.maybeFind();
    final cacheEntryCount = cacheManager?.entryCount ?? 0;
    final cacheSizeText = cacheManager != null
        ? CacheMetrics.formatBytes(cacheManager.totalSizeBytes)
        : "settings.diagnostics.unknown".tr;
    final offline = OfflineModeService.ensure();
    final queueStats = offline.getQueueStats();
    final queueLastSyncMs = (queueStats['lastSyncAt'] as int?) ?? 0;
    final queueLastSyncText = queueLastSyncMs <= 0
        ? "common.no_results".tr
        : DateTime.fromMillisecondsSinceEpoch(queueLastSyncMs).toString();
    final lastSignIn =
        FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;
    final loginDate = lastSignIn == null
        ? "settings.diagnostics.unknown".tr
        : "${lastSignIn.day.toString().padLeft(2, '0')}.${lastSignIn.month.toString().padLeft(2, '0')}.${lastSignIn.year}";
    final loginTime = lastSignIn == null
        ? "settings.diagnostics.unknown".tr
        : "${lastSignIn.hour.toString().padLeft(2, '0')}:${lastSignIn.minute.toString().padLeft(2, '0')}";
    final loginHours = lastSignIn == null
        ? 0.0
        : (now.difference(lastSignIn).inMinutes / 60).clamp(1.0, 99999.0);
    final sinceLoginEstimatedTotal = lastSignIn == null
        ? 0.0
        : (monthlyAvgPerHour * loginHours).clamp(0.0, monthlyTotalMB);
    final sinceLoginAvgPerHour = lastSignIn == null
        ? 0.0
        : (sinceLoginEstimatedTotal / loginHours).clamp(0.0, monthlyAvgPerHour);

    Get.dialog(
      AlertDialog(
        title: Text("settings.diagnostics.data_usage".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${'settings.diagnostics.network'.tr}: ${stats['currentNetwork']}"),
            Text(
                "${'settings.diagnostics.connected'.tr}: ${stats['isConnected']}"),
            Text(
              "${'settings.diagnostics.monthly_total'.tr}: ${stats['monthlyUsageMB']} MB",
            ),
            Text(
                "${'settings.diagnostics.monthly_limit'.tr}: ${stats['monthlyLimitMB']} MB"),
            Text(
                "${'settings.diagnostics.remaining'.tr}: ${stats['remainingMB']} MB"),
            Text(
              "${'settings.diagnostics.limit_usage'.tr}: ${stats['dataUsagePercentage'].toStringAsFixed(1)}%",
            ),
            Text(
                "${'settings.diagnostics.wifi_usage'.tr}: ${stats['wifiUsageMB']} MB"),
            Text(
                "${'settings.diagnostics.cellular_usage'.tr}: ${stats['cellularUsageMB']} MB"),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.time_ranges".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "1) ${'settings.diagnostics.this_month_actual'.tr}: ${monthlyTotalMB.toStringAsFixed(1)} MB",
            ),
            Text(
              "${'settings.diagnostics.hourly_average'.tr}: ${monthlyAvgPerHour.toStringAsFixed(2)} MB/saat",
            ),
            Text(
              "2) ${'settings.diagnostics.since_login_estimated'.tr}: ${sinceLoginEstimatedTotal.toStringAsFixed(1)} MB",
            ),
            Text(
              "${'settings.diagnostics.hourly_average'.tr}: ${sinceLoginAvgPerHour.toStringAsFixed(2)} MB/saat",
            ),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.details".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("${'settings.diagnostics.upload'.tr}: ${usage.uploadedMB} MB"),
            Text(
                "${'settings.diagnostics.download'.tr}: ${usage.downloadedMB} MB"),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.cache".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
                "${'settings.diagnostics.saved_media_count'.tr}: $cacheEntryCount"),
            Text("${'settings.diagnostics.occupied_space'.tr}: $cacheSizeText"),
            const SizedBox(height: 8),
            Text(
              "settings.diagnostics.offline_queue".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
                "${'settings.diagnostics.pending'.tr}: ${queueStats['pending'] ?? 0}"),
            Text(
                "${'settings.diagnostics.dead_letter'.tr}: ${queueStats['deadLetter'] ?? 0}"),
            Text(
                "${'settings.diagnostics.status'.tr}: ${(queueStats['isSyncing'] ?? false) ? 'settings.diagnostics.syncing'.tr : 'settings.diagnostics.idle'.tr}"),
            Text(
                "${'settings.diagnostics.processed_total'.tr}: ${queueStats['processedCount'] ?? 0}"),
            Text(
                "${'settings.diagnostics.failed_total'.tr}: ${queueStats['failedCount'] ?? 0}"),
            Text("${'settings.diagnostics.last_sync'.tr}: $queueLastSyncText"),
            const SizedBox(height: 8),
            Text("${'settings.diagnostics.login_date'.tr}: $loginDate"),
            Text("${'settings.diagnostics.login_time'.tr}: $loginTime"),
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

  void _ensureDiagnosticsServices() {
    ErrorHandlingService.ensure();
    NetworkAwarenessService.ensure();
    UploadQueueService.ensure();
    DraftService.ensure();
    PostEditingService.ensure();
    MediaEnhancementService.ensure();
    OfflineModeService.ensure();
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
            ],
          ),
        ),
      ),
    );
  }

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
                  await NetworkAwarenessService.ensure().resetDataUsage();
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
                  final prefetch = PrefetchScheduler.maybeFind();
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
                  final prefetch = PrefetchScheduler.maybeFind();
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

  void _showOfflineQueueDetails() {
    final offline = OfflineModeService.ensure();

    Get.dialog(
      AlertDialog(
        title: Text("settings.diagnostics.offline_queue_detail".tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            final pending = offline.pendingActions.toList();
            final dead = offline.deadLetterActions.toList();
            final stats = offline.getQueueStats();

            String fmtMs(int ms) {
              if (ms <= 0) return '-';
              final dt = DateTime.fromMillisecondsSinceEpoch(ms);
              return dt.toString();
            }

            Widget buildItem(PendingAction a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'attempt=${a.attemptCount}  next=${fmtMs(a.nextAttemptAtMs)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      if ((a.lastError ?? '').isNotEmpty)
                        Text(
                          'error=${a.lastError}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "${'settings.diagnostics.online'.tr}: ${stats['isOnline']}"),
                  Text(
                      "${'settings.diagnostics.sync'.tr}: ${stats['isSyncing']}"),
                  Text(
                      "${'settings.diagnostics.pending'.tr}: ${pending.length}"),
                  Text(
                      "${'settings.diagnostics.dead_letter'.tr}: ${dead.length}"),
                  Text(
                      "${'settings.diagnostics.processed'.tr}: ${stats['processedCount'] ?? 0}"),
                  Text(
                      "${'settings.diagnostics.failed'.tr}: ${stats['failedCount'] ?? 0}"),
                  const SizedBox(height: 10),
                  Text(
                    'settings.diagnostics.pending_first8'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (pending.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.black54)),
                  ...pending.take(8).map(buildItem),
                  const SizedBox(height: 8),
                  Text(
                    'settings.diagnostics.dead_letter_first8'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (dead.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.black54)),
                  ...dead.take(8).map(buildItem),
                ],
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance
                  .processPendingNow(ignoreBackoff: true);
            },
            child: Text('settings.diagnostics.sync_now'.tr),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.retryDeadLetter(limit: 100);
            },
            child: Text('settings.diagnostics.dead_letter_retry'.tr),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.clearDeadLetter();
            },
            child: Text('settings.diagnostics.dead_letter_clear'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
          ),
        ],
      ),
    );
  }

  void _showLastErrorSummary() {
    final errorService = ErrorHandlingService.ensure();
    final last = errorService.getLastErrorSummary();

    Get.dialog(
      AlertDialog(
        title: Text("settings.diagnostics.last_error_summary".tr),
        content: last == null
            ? Text("settings.diagnostics.no_recorded_error".tr)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "${'settings.diagnostics.error_code'.tr}: ${last['code']}"),
                  Text(
                      "${'settings.diagnostics.error_category'.tr}: ${last['category']}"),
                  Text(
                      "${'settings.diagnostics.error_severity'.tr}: ${last['severity']}"),
                  Text(
                      "${'settings.diagnostics.error_retryable'.tr}: ${last['retryable']}"),
                  Text(
                      "${'settings.diagnostics.error_message'.tr}: ${last['userFriendlyMessage']}"),
                  Text(
                      "${'settings.diagnostics.error_time'.tr}: ${last['timestamp']}"),
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
}
