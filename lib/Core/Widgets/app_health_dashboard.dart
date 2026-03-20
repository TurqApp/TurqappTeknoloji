import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Services/error_handling_service.dart';
import '../Services/network_awareness_service.dart';
import '../Services/upload_queue_service.dart';
import '../Services/draft_service.dart';
import '../Services/post_editing_service.dart';
import '../Services/media_enhancement_service.dart';
import '../Services/PlaybackIntelligence/playback_kpi_service.dart';
import '../Services/PlaybackIntelligence/playback_policy_engine.dart';
import '../Services/PlaybackIntelligence/storage_budget_manager.dart';
import '../Services/PlaybackIntelligence/telemetry_threshold_policy.dart';
import '../Services/PlaybackIntelligence/telemetry_threshold_policy_adapter.dart';
import '../Services/SegmentCache/cache_manager.dart';
import '../Services/SegmentCache/cache_metrics.dart';
import '../Services/SegmentCache/prefetch_scheduler.dart';

class AppHealthDashboard extends StatelessWidget {
  const AppHealthDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    _ensureDashboardServices();
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.diagnostics.app_health_panel'.tr),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Get.forceAppUpdate(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallHealthCard(),
            const SizedBox(height: 20),
            _buildKpiAlertCard(),
            const SizedBox(height: 20),
            _buildPlaybackIntelligenceCard(),
            const SizedBox(height: 20),
            _buildServiceStatusGrid(),
            const SizedBox(height: 20),
            _buildPerformanceMetrics(),
            const SizedBox(height: 20),
            _buildUsageStatistics(),
          ],
        ),
      ),
    );
  }

  void _ensureDashboardServices() {
    if (!Get.isRegistered<ErrorHandlingService>()) {
      Get.put(ErrorHandlingService());
    }
    if (!Get.isRegistered<NetworkAwarenessService>()) {
      Get.put(NetworkAwarenessService());
    }
    if (!Get.isRegistered<UploadQueueService>()) {
      Get.put(UploadQueueService());
    }
    if (!Get.isRegistered<DraftService>()) {
      Get.put(DraftService());
    }
    if (!Get.isRegistered<PostEditingService>()) {
      Get.put(PostEditingService());
    }
    if (!Get.isRegistered<MediaEnhancementService>()) {
      Get.put(MediaEnhancementService());
    }
    if (!Get.isRegistered<StorageBudgetManager>()) {
      Get.put(StorageBudgetManager());
    }
    if (!Get.isRegistered<PlaybackKpiService>()) {
      Get.put(PlaybackKpiService());
    }
    if (!Get.isRegistered<PlaybackPolicyEngine>()) {
      Get.put(PlaybackPolicyEngine());
    }
  }

  Widget _buildPlaybackIntelligenceCard() {
    final budgetManager = Get.isRegistered<StorageBudgetManager>()
        ? Get.find<StorageBudgetManager>()
        : Get.put(StorageBudgetManager());
    final profile = budgetManager.currentProfile;
    final usage = Get.isRegistered<SegmentCacheManager>()
        ? StorageBudgetManager.usageSnapshotForProfile(
            profile,
            streamUsageBytes: Get.find<SegmentCacheManager>().totalSizeBytes,
          )
        : null;
    final recentProtectionWindow =
        StorageBudgetManager.recentProtectionWindowForUsage(
      profile,
      streamUsageBytes: usage?.streamUsageBytes ?? 0,
    );
    final policy = Get.isRegistered<PlaybackPolicyEngine>()
        ? Get.find<PlaybackPolicyEngine>().snapshot()
        : null;
    final kpiService = Get.isRegistered<PlaybackKpiService>()
        ? Get.find<PlaybackKpiService>()
        : null;
    final recentEvents = kpiService?.recentEvents ?? const <PlaybackKpiEvent>[];
    final feedCacheSummary = kpiService?.summarizeCacheFirst(
      surfaceKeyPrefix: 'feed_',
    );
    final shortCacheSummary = kpiService?.summarizeCacheFirst(
      surfaceKeyPrefix: 'short_',
    );
    final feedRenderSummary = kpiService?.summarizeRenderDiff(surface: 'feed');
    final shortRenderSummary =
        kpiService?.summarizeRenderDiff(surface: 'short');
    final feedPlaybackSummary =
        kpiService?.summarizePlaybackWindow(surface: 'feed');
    final shortPlaybackSummary =
        kpiService?.summarizePlaybackWindow(surface: 'short');
    final lastEvent = recentEvents.isNotEmpty ? recentEvents.last : null;
    PlaybackKpiEvent? lastIntentEvent;
    PlaybackKpiEvent? lastCacheFirstEvent;
    PlaybackKpiEvent? lastRenderDiffEvent;
    PlaybackKpiEvent? lastPlaybackWindowEvent;
    for (final event in recentEvents.reversed) {
      if (event.type == PlaybackKpiEventType.playbackIntent) {
        lastIntentEvent = event;
      } else if (event.type == PlaybackKpiEventType.cacheFirstLifecycle) {
        lastCacheFirstEvent = event;
      } else if (event.type == PlaybackKpiEventType.renderDiff) {
        lastRenderDiffEvent = event;
      } else if (event.type == PlaybackKpiEventType.playbackWindow) {
        lastPlaybackWindowEvent = event;
      }
      if (lastIntentEvent != null &&
          lastCacheFirstEvent != null &&
          lastRenderDiffEvent != null &&
          lastPlaybackWindowEvent != null) {
        break;
      }
    }
    final scheduler = Get.isRegistered<PrefetchScheduler>()
        ? Get.find<PrefetchScheduler>()
        : null;
    final pressureLabel = usage == null
        ? null
        : usage.crossedHardStop
            ? 'hard_stop'
            : usage.crossedSoftStop
                ? 'soft_stop'
                : usage.softUsageRatio >= 0.75
                    ? 'approaching_soft_stop'
                    : 'healthy';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app_health.playback_intelligence'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('app_health.plan_gb'
                .trParams({'gb': profile.planGb.toString()})),
            Text('app_health.media_quota'.trParams(
                {'value': CacheMetrics.formatBytes(profile.mediaQuotaBytes)})),
            Text('app_health.image_quota'.trParams(
                {'value': CacheMetrics.formatBytes(profile.imageQuotaBytes)})),
            Text('app_health.metadata_quota'.trParams({
              'value': CacheMetrics.formatBytes(profile.metadataQuotaBytes)
            })),
            Text('app_health.soft_hard_stop'.trParams({
              'soft':
                  CacheMetrics.formatBytes(profile.streamCacheSoftStopBytes),
              'hard':
                  CacheMetrics.formatBytes(profile.streamCacheHardStopBytes),
            })),
            Text('app_health.recent_protect_window'
                .trParams({'count': recentProtectionWindow.toString()})),
            if (usage != null) ...[
              const SizedBox(height: 10),
              Text('app_health.active_stream_usage'.trParams(
                  {'value': CacheMetrics.formatBytes(usage.streamUsageBytes)})),
              Text(
                'Soft oran: ${(usage.softUsageRatio * 100).toStringAsFixed(1)}%  •  Hard oran: ${(usage.hardUsageRatio * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Kalan soft/hard: '
                '${CacheMetrics.formatBytes(usage.remainingBeforeSoftStopBytes)} / '
                '${CacheMetrics.formatBytes(usage.remainingBeforeHardStopBytes)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Budget durumu: $pressureLabel',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (policy != null) ...[
              const SizedBox(height: 10),
              Text(
                'Policy: ${policy.policyTag}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Mode: ${policy.mode.name}  •  Reason: ${policy.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Startup/Ahead: ${policy.startupWindowSegments}/${policy.aheadWindowSegments}  •  Prefetch: ${policy.allowBackgroundPrefetch ? 'acik' : 'kapali'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (scheduler != null) ...[
              const SizedBox(height: 10),
              Text(
                'Prefetch: ${scheduler.isMobileSeedMode ? 'mobile_seed' : 'standard'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Queue/active/max: ${scheduler.queueSize}/${scheduler.activeDownloads}/${scheduler.maxConcurrentDownloads}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Feed ready: ${scheduler.feedReadyCount}/${scheduler.feedWindowCount} (${(scheduler.feedReadyRatio * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Dispatch latency: ${scheduler.avgQueueDispatchLatencyMs.toStringAsFixed(0)} ms',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (feedCacheSummary != null || shortCacheSummary != null) ...[
              const SizedBox(height: 10),
              const Text(
                'Cache-first ozeti',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (feedCacheSummary != null)
                Text(
                  'Feed hit/live/fail: '
                  '${(feedCacheSummary.localHitRatio * 100).toStringAsFixed(0)}%  •  '
                  '${feedCacheSummary.liveSuccessCount}/${feedCacheSummary.liveFailCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              if (shortCacheSummary != null)
                Text(
                  'Short local/warm/preserve: '
                  '${shortCacheSummary.localHitCount}/${shortCacheSummary.warmHitCount}/${shortCacheSummary.preservedPreviousCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
            ],
            if (feedRenderSummary != null || shortRenderSummary != null) ...[
              const SizedBox(height: 10),
              const Text(
                'Render ozeti',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (feedRenderSummary != null)
                Text(
                  'Feed patch avg/max: '
                  '${feedRenderSummary.averageOperations.toStringAsFixed(1)} / '
                  '${feedRenderSummary.maxOperations}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              if (shortRenderSummary != null)
                Text(
                  'Short patch avg/max: '
                  '${shortRenderSummary.averageOperations.toStringAsFixed(1)} / '
                  '${shortRenderSummary.maxOperations}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
            ],
            if (feedPlaybackSummary != null ||
                shortPlaybackSummary != null) ...[
              const SizedBox(height: 10),
              const Text(
                'Playback window ozeti',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (feedPlaybackSummary != null)
                Text(
                  'Feed visible/lost: '
                  '${feedPlaybackSummary.averageVisibleCount.toStringAsFixed(1)} / '
                  '${feedPlaybackSummary.activeLostCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              if (shortPlaybackSummary != null)
                Text(
                  'Short hot/attached: '
                  '${shortPlaybackSummary.averageHotCount.toStringAsFixed(1)} / '
                  '${shortPlaybackSummary.maxAttachedPlayers}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
            ],
            const SizedBox(height: 10),
            Text(
              lastEvent == null
                  ? 'Son KPI olayi henuz yok'
                  : 'Son KPI: ${lastEvent.type.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (lastEvent != null)
              Text(
                lastEvent.payload.entries
                    .take(3)
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join('  •  '),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            if (lastIntentEvent != null) ...[
              const SizedBox(height: 8),
              Text(
                'Son intent: '
                '${lastIntentEvent.payload['source']}  •  '
                '${lastIntentEvent.payload['audible'] == true ? 'sesli' : 'sessiz'}  •  '
                '${lastIntentEvent.payload['stableFocus'] == true ? 'stabil odak' : 'gecici odak'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (lastCacheFirstEvent != null) ...[
              const SizedBox(height: 8),
              Text(
                'Son cache-first: '
                '${lastCacheFirstEvent.payload['surfaceKey']}  •  '
                '${lastCacheFirstEvent.payload['event']}  •  '
                '${lastCacheFirstEvent.payload['source']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (lastRenderDiffEvent != null) ...[
              const SizedBox(height: 8),
              Text(
                'Son render diff: '
                '${lastRenderDiffEvent.payload['surface']}  •  '
                '${lastRenderDiffEvent.payload['stage']}  •  '
                '${lastRenderDiffEvent.payload['operations'] ?? lastRenderDiffEvent.payload['renderCount']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (lastPlaybackWindowEvent != null) ...[
              const SizedBox(height: 8),
              Text(
                'Son playback window: '
                '${lastPlaybackWindowEvent.payload['surface']}  •  '
                'active ${lastPlaybackWindowEvent.payload['activeIndex']}  •  '
                'hot ${lastPlaybackWindowEvent.payload['hotCount']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallHealthCard() {
    return GetBuilder<ErrorHandlingService>(
      builder: (errorService) {
        final health = errorService.getSystemHealth();
        final status = health['status'] as String;

        Color statusColor;
        IconData statusIcon;
        String statusText;
        String statusDescription;

        switch (status) {
          case 'good':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = 'app_health.status_excellent'.tr;
            statusDescription = 'app_health.status_excellent_desc'.tr;
            break;
          case 'fair':
            statusColor = Colors.orange;
            statusIcon = Icons.warning;
            statusText = 'app_health.status_good'.tr;
            statusDescription = 'app_health.status_good_desc'.tr;
            break;
          case 'poor':
            statusColor = Colors.red;
            statusIcon = Icons.error;
            statusText = 'app_health.status_attention'.tr;
            statusDescription = 'app_health.status_attention_desc'.tr;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
            statusText = 'common.unknown'.tr;
            statusDescription = 'app_health.status_unknown_desc'.tr;
        }

        return Card(
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.1),
                  statusColor.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 40),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Durumu: $statusText',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          statusDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(
                      'app_health.recent_errors_30m'.tr,
                      '${health['recentErrors']}',
                      Icons.bug_report,
                      (health['recentErrors'] as int) > 5
                          ? Colors.orange
                          : Colors.green,
                    ),
                    _buildMetric(
                      'app_health.connection'.tr,
                      (health['isOnline'] as bool)
                          ? 'app_health.online_status'.tr
                          : 'app_health.offline_status'.tr,
                      Icons.wifi,
                      (health['isOnline'] as bool) ? Colors.blue : Colors.red,
                    ),
                    _buildMetric(
                      'app_health.critical_short'.tr,
                      '${health['criticalErrors']}',
                      Icons.error_outline,
                      health['criticalErrors'] > 0 ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceStatusGrid() {
    final health = _getSystemHealth();
    final networkStats = _getNetworkStats();
    final uploadStats = _getUploadStats();
    final draftStats = _getDraftStats();
    final editStats = _getEditStats();
    final mediaStats = _getMediaStats();

    final errorStatus = (health['status'] ?? 'unknown').toString();
    final uploadBekliyor = (uploadStats['pending'] as num?)?.toInt() ?? 0;
    final draftTotal = (draftStats['total'] as num?)?.toInt() ?? 0;
    final canUndo = (editStats['canUndo'] as bool?) ?? false;
    final mediaProcessing = (mediaStats['isProcessing'] as bool?) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'app_health.service_status'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildServiceCard(
              'app_health.error_management'.tr,
              _errorStatusLabel(errorStatus),
              Icons.security,
              _errorStatusColor(errorStatus),
              () => _showErrorStats(),
            ),
            _buildServiceCard(
              'app_health.network_awareness'.tr,
              (networkStats['currentNetwork'] ??
                      'app_health.unknown_network'.tr)
                  .toString(),
              Icons.network_check,
              (networkStats['isConnected'] as bool? ?? false)
                  ? Colors.blue
                  : Colors.red,
              () => _showNetworkStats(),
            ),
            _buildServiceCard(
              'app_health.upload_queue'.tr,
              uploadBekliyor > 0
                  ? 'app_health.pending_count'
                      .trParams({'count': '$uploadBekliyor'})
                  : 'app_health.idle'.tr,
              Icons.cloud_upload,
              uploadBekliyor > 0 ? Colors.orange : Colors.green,
              () => _showUploadStats(),
            ),
            _buildServiceCard(
              'app_health.autosave'.tr,
              'app_health.draft_count'.trParams({'count': '$draftTotal'}),
              Icons.save,
              Colors.teal,
              () => _showDraftStats(),
            ),
            _buildServiceCard(
              'app_health.smart_editing'.tr,
              canUndo ? 'app_health.undo_ready'.tr : 'app_health.standby'.tr,
              Icons.edit_note,
              Colors.purple,
              () => _showEditingStats(),
            ),
            _buildServiceCard(
              'app_health.media_enhancement'.tr,
              mediaProcessing
                  ? 'app_health.processing'.tr
                  : 'app_health.idle'.tr,
              Icons.photo_filter,
              mediaProcessing ? Colors.indigo : Colors.green,
              () => _showMediaStats(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiAlertCard() {
    final networkStats = _getNetworkStats();
    final errorStats = _getErrorStats();
    final uploadStats = _getUploadStats();

    final dataUsagePercent =
        (networkStats['dataUsagePercentage'] as num?)?.toDouble() ?? 0.0;
    final criticalErrors = (errorStats['critical'] as num?)?.toInt() ?? 0;
    final pendingUploads = (uploadStats['pending'] as num?)?.toInt() ?? 0;

    double cacheHitRate = 0;
    if (Get.isRegistered<SegmentCacheManager>()) {
      cacheHitRate = Get.find<SegmentCacheManager>().metrics.cacheHitRate;
    }

    final kpiReport = Get.isRegistered<PlaybackKpiService>()
        ? TelemetryThresholdPolicyAdapter.evaluateKpiService(
            Get.find<PlaybackKpiService>(),
          )
        : const TelemetryThresholdReport(issues: <TelemetryThresholdIssue>[]);

    final alerts = <String>[];
    if (dataUsagePercent >= 85) {
      alerts.add('app_health.alert_data_usage_critical'.tr);
    }
    if (criticalErrors > 0) {
      alerts.add('app_health.alert_critical_error'.tr);
    }
    if (pendingUploads >= 5) {
      alerts.add('app_health.alert_upload_queue_busy'.tr);
    }
    if (cacheHitRate < 0.60) {
      alerts.add('app_health.alert_cache_hit_low'.tr);
    }
    for (final issue in kpiReport.issues.take(3)) {
      final prefix = issue.severity == TelemetryThresholdSeverity.blocking
          ? 'BLOCK'
          : 'WARN';
      alerts.add('$prefix ${issue.surface}: ${issue.code}');
    }

    final hasAlert = alerts.isNotEmpty;

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (hasAlert ? Colors.red : Colors.green).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (hasAlert ? Colors.red : Colors.green).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasAlert
                  ? 'app_health.kpi_status_alert'.tr
                  : 'app_health.kpi_status_normal'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: hasAlert ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text('app_health.cache_hit'.trParams(
                {'value': '${(cacheHitRate * 100).toStringAsFixed(1)}%'})),
            Text('app_health.data_usage'.trParams(
                {'value': '${dataUsagePercent.toStringAsFixed(1)}%'})),
            Text('app_health.critical_error_count'
                .trParams({'count': criticalErrors.toString()})),
            Text('app_health.pending_uploads'
                .trParams({'count': pendingUploads.toString()})),
            const SizedBox(height: 8),
            Text(
              hasAlert ? alerts.join(' • ') : 'app_health.kpi_all_normal'.tr,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    String title,
    String status,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final networkStats = _getNetworkStats();
    final errorStats = _getErrorStats();
    final uploadStats = _getUploadStats();
    final mediaStats = _getMediaStats();

    final totalErrors = (errorStats['total'] as num?)?.toDouble() ?? 0;
    final criticalErrors = (errorStats['critical'] as num?)?.toDouble() ?? 0;
    final errorRatio =
        totalErrors <= 0 ? 0.0 : (criticalErrors / totalErrors).clamp(0.0, 1.0);

    final dataUsagePercent =
        ((networkStats['dataUsagePercentage'] as num?)?.toDouble() ?? 0.0) /
            100;

    final uploadTotal = (uploadStats['total'] as num?)?.toDouble() ?? 0;
    final uploadBekliyor = (uploadStats['pending'] as num?)?.toDouble() ?? 0;
    final queuePressure =
        uploadTotal <= 0 ? 0.0 : (uploadBekliyor / uploadTotal).clamp(0.0, 1.0);

    final processingProgress =
        (mediaStats['processingProgress'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app_health.performance_metrics'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildProgressIndicator('app_health.network_data_usage'.tr,
                dataUsagePercent, Colors.blue),
            _buildProgressIndicator('app_health.upload_queue_pressure'.tr,
                queuePressure, Colors.orange),
            _buildProgressIndicator(
                'app_health.critical_error_ratio'.tr, errorRatio, Colors.red),
            _buildProgressIndicator(
              'app_health.media_processing_progress'.tr,
              processingProgress.clamp(0.0, 1.0),
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${(value * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatistics() {
    final uploadStats = _getUploadStats();
    final draftStats = _getDraftStats();
    final editStats = _getEditStats();
    final mediaStats = _getMediaStats();
    final errorStats = _getErrorStats();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app_health.usage_statistics'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'app_health.completed_uploads'.tr,
                    '${uploadStats['completed'] ?? 0}',
                    Icons.cloud_done,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'app_health.media_edits'.tr,
                    '${mediaStats['totalEdits'] ?? 0}',
                    Icons.image,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'app_health.saved_drafts'.tr,
                    '${draftStats['total'] ?? 0}',
                    Icons.drafts,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'app_health.processed_errors'.tr,
                    '${errorStats['total'] ?? 0}',
                    Icons.healing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'app_health.last_edit_action'.tr,
                    '${editStats['recentActions'] ?? 0}',
                    Icons.history,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getSystemHealth() {
    if (Get.isRegistered<ErrorHandlingService>()) {
      return Get.find<ErrorHandlingService>().getSystemHealth();
    }
    return {
      'status': 'unknown',
      'recentErrors': 0,
      'criticalErrors': 0,
      'isOnline': false,
    };
  }

  Map<String, dynamic> _getErrorStats() {
    if (Get.isRegistered<ErrorHandlingService>()) {
      return Get.find<ErrorHandlingService>().getErrorStats();
    }
    return {
      'total': 0,
      'critical': 0,
      'last24Hours': 0,
      'lastWeek': 0,
      'retryableErrors': 0,
    };
  }

  Map<String, dynamic> _getNetworkStats() {
    if (Get.isRegistered<NetworkAwarenessService>()) {
      return Get.find<NetworkAwarenessService>().getNetworkStats();
    }
    return {
      'currentNetwork': 'Bilinmiyor',
      'isConnected': false,
      'dataUsagePercentage': 0.0,
      'monthlyUsageMB': 0.0,
      'remainingMB': 0.0,
    };
  }

  Map<String, dynamic> _getUploadStats() {
    if (Get.isRegistered<UploadQueueService>()) {
      return Get.find<UploadQueueService>().getQueueStats();
    }
    return {
      'total': 0,
      'pending': 0,
      'completed': 0,
      'failed': 0,
      'processing': false,
      'paused': false,
    };
  }

  Map<String, dynamic> _getDraftStats() {
    if (Get.isRegistered<DraftService>()) {
      return Get.find<DraftService>().getDraftStats();
    }
    return {
      'total': 0,
      'today': 0,
      'thisWeek': 0,
      'withMedia': 0,
      'textOnly': 0,
    };
  }

  Map<String, dynamic> _getEditStats() {
    if (Get.isRegistered<PostEditingService>()) {
      return Get.find<PostEditingService>().getEditStatistics();
    }
    return {
      'totalActions': 0,
      'recentActions': 0,
      'canUndo': false,
      'canRedo': false,
      'suggestionsGenerated': 0,
      'smartSuggestionsEnabled': false,
    };
  }

  Map<String, dynamic> _getMediaStats() {
    if (Get.isRegistered<MediaEnhancementService>()) {
      return Get.find<MediaEnhancementService>().getProcessingStats();
    }
    return {
      'totalEdits': 0,
      'imageEdits': 0,
      'videoEdits': 0,
      'isProcessing': false,
      'processingProgress': 0.0,
      'hasAdjustments': false,
      'selectedFilter': 'Yok',
    };
  }

  String _errorStatusLabel(String status) {
    switch (status) {
      case 'good':
        return 'app_health.error_status_healthy'.tr;
      case 'fair':
        return 'app_health.error_status_medium'.tr;
      case 'poor':
        return 'app_health.error_status_risky'.tr;
      default:
        return 'common.unknown'.tr;
    }
  }

  Color _errorStatusColor(String status) {
    switch (status) {
      case 'good':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showErrorStats() {
    if (Get.isRegistered<ErrorHandlingService>()) {
      final errorService = Get.find<ErrorHandlingService>();
      final stats = errorService.getErrorStats();

      Get.dialog(
        AlertDialog(
          title: Text('app_health.error_stats_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('app_health.error_total'
                  .trParams({'count': '${stats['total']}'})),
              Text('app_health.error_critical'
                  .trParams({'count': '${stats['critical']}'})),
              Text('app_health.error_last_24h'
                  .trParams({'count': '${stats['last24Hours']}'})),
              Text('app_health.error_last_week'
                  .trParams({'count': '${stats['lastWeek']}'})),
              Text('app_health.error_retryable'
                  .trParams({'count': '${stats['retryableErrors']}'})),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('common.close'.tr),
            ),
          ],
        ),
      );
    }
  }

  void _showNetworkStats() {
    if (Get.isRegistered<NetworkAwarenessService>()) {
      final networkService = Get.find<NetworkAwarenessService>();
      final stats = networkService.getNetworkStats();

      Get.dialog(
        AlertDialog(
          title: Text('app_health.network_stats_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('app_health.network_label'
                  .trParams({'value': '${stats['currentNetwork']}'})),
              Text('app_health.connected_label'
                  .trParams({'value': '${stats['isConnected']}'})),
              Text('app_health.data_usage'.trParams({
                'value': '${stats['dataUsagePercentage'].toStringAsFixed(1)}%'
              })),
              Text('app_health.monthly_usage_mb'
                  .trParams({'value': '${stats['monthlyUsageMB']} MB'})),
              Text('app_health.remaining_mb'
                  .trParams({'value': '${stats['remainingMB']} MB'})),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('common.close'.tr),
            ),
          ],
        ),
      );
    }
  }

  void _showUploadStats() {
    if (Get.isRegistered<UploadQueueService>()) {
      final uploadService = Get.find<UploadQueueService>();
      final stats = uploadService.getQueueStats();

      Get.dialog(
        AlertDialog(
          title: Text('app_health.upload_stats_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('app_health.total_label'
                  .trParams({'count': '${stats['total']}'})),
              Text('app_health.pending_label'
                  .trParams({'count': '${stats['pending']}'})),
              Text('app_health.completed_label'
                  .trParams({'count': '${stats['completed']}'})),
              Text('app_health.failed_label'
                  .trParams({'count': '${stats['failed']}'})),
              Text('app_health.processing_label'
                  .trParams({'count': '${stats['processing']}'})),
              Text('app_health.paused_label'
                  .trParams({'count': '${stats['paused']}'})),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('common.close'.tr),
            ),
          ],
        ),
      );
    }
  }

  void _showDraftStats() {
    if (Get.isRegistered<DraftService>()) {
      final draftService = Get.find<DraftService>();
      final stats = draftService.getDraftStats();

      Get.dialog(
        AlertDialog(
          title: Text('app_health.draft_stats_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('app_health.total_drafts'
                  .trParams({'count': '${stats['total']}'})),
              Text('app_health.today_label'
                  .trParams({'count': '${stats['today']}'})),
              Text('app_health.this_week_label'
                  .trParams({'count': '${stats['thisWeek']}'})),
              Text('app_health.with_media_label'
                  .trParams({'count': '${stats['withMedia']}'})),
              Text('app_health.text_only_label'
                  .trParams({'count': '${stats['textOnly']}'})),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('common.close'.tr),
            ),
          ],
        ),
      );
    }
  }

  void _showEditingStats() {
    if (Get.isRegistered<PostEditingService>()) {
      final editingService = Get.find<PostEditingService>();
      final stats = editingService.getEditStatistics();

      Get.dialog(
        AlertDialog(
          title: Text('app_health.editing_stats_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('app_health.total_actions'
                  .trParams({'count': '${stats['totalActions']}'})),
              Text('app_health.recent_actions'
                  .trParams({'count': '${stats['recentActions']}'})),
              Text('app_health.can_undo_label'
                  .trParams({'value': '${stats['canUndo']}'})),
              Text('app_health.can_redo_label'
                  .trParams({'value': '${stats['canRedo']}'})),
              Text('app_health.suggestions_count'
                  .trParams({'count': '${stats['suggestionsGenerated']}'})),
              Text('app_health.smart_suggestions_label'
                  .trParams({'value': '${stats['smartSuggestionsEnabled']}'})),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('common.close'.tr),
            ),
          ],
        ),
      );
    }
  }

  void _showMediaStats() {
    if (Get.isRegistered<MediaEnhancementService>()) {
      final mediaService = Get.find<MediaEnhancementService>();
      final stats = mediaService.getProcessingStats();

      Get.dialog(
        AlertDialog(
          title: Text('app_health.media_stats_title'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('app_health.total_edits'
                  .trParams({'count': '${stats['totalEdits']}'})),
              Text('app_health.image_edits'
                  .trParams({'count': '${stats['imageEdits']}'})),
              Text('app_health.video_edits'
                  .trParams({'count': '${stats['videoEdits']}'})),
              Text('app_health.processing_label'
                  .trParams({'count': '${stats['isProcessing']}'})),
              Text('app_health.selected_filter'
                  .trParams({'value': '${stats['selectedFilter']}'})),
              Text('app_health.has_adjustments'
                  .trParams({'value': '${stats['hasAdjustments']}'})),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('common.close'.tr),
            ),
          ],
        ),
      );
    }
  }
}
