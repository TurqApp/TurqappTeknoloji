part of 'app_health_dashboard.dart';

extension _AppHealthDashboardCardsPart on _AppHealthDashboardState {
  Widget _buildPlaybackIntelligenceCard() {
    final budgetManager = StorageBudgetManager.ensure();
    final profile = budgetManager.currentProfile;
    final cacheManager = SegmentCacheManager.maybeFind();
    final usage = cacheManager != null
        ? storageBudgetUsageSnapshotForProfile(
            profile,
            streamUsageBytes: cacheManager.totalSizeBytes,
          )
        : null;
    final recentProtectionWindow = storageBudgetRecentProtectionWindowForUsage(
      profile,
      streamUsageBytes: usage?.streamUsageBytes ?? 0,
    );
    final policy = maybeFindPlaybackPolicyEngine()?.snapshot();
    final kpiService = maybeFindPlaybackKpiService();
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
    final scheduler = maybeFindPrefetchScheduler();
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
    final health = _getSystemHealth();
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
    final cache = SegmentCacheManager.maybeFind();
    if (cache != null) {
      cacheHitRate = cache.metrics.cacheHitRate;
    }

    final playbackKpi = maybeFindPlaybackKpiService();
    final kpiReport = playbackKpi != null
        ? TelemetryThresholdPolicyAdapter.evaluateKpiService(playbackKpi)
        : TelemetryThresholdReport(issues: <TelemetryThresholdIssue>[]);

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
}
