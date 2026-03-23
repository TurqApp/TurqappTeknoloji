// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/settings.dart';

extension _SettingsViewDiagnosticsCachePart on _SettingsViewState {
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
}
