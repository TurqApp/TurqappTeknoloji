// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/settings.dart';

extension _SettingsViewDiagnosticsUsagePart on _SettingsViewState {
  void _showDataUsageDialog() {
    final stats = _settingsNetworkRuntimeService.getNetworkStats();
    final usage = _settingsNetworkRuntimeService.dataUsage;
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
    final offline = ensureOfflineModeService();
    final queueStats = offline.getQueueStats();
    final queueLastSyncMs = (queueStats['lastSyncAt'] as int?) ?? 0;
    final queueLastSyncText = queueLastSyncMs <= 0
        ? "common.no_results".tr
        : DateTime.fromMillisecondsSinceEpoch(queueLastSyncMs).toString();
    final lastSignIn = userService.currentAuthUser?.metadata.lastSignInTime;
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
}
