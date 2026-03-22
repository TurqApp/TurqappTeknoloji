part of 'app_health_dashboard.dart';

extension _AppHealthDashboardDialogsPart on _AppHealthDashboardState {
  void _ensureDashboardServices() {
    ErrorHandlingService.ensure();
    NetworkAwarenessService.ensure();
    UploadQueueService.ensure();
    DraftService.ensure();
    PostEditingService.ensure();
    MediaEnhancementService.ensure();
    StorageBudgetManager.ensure();
    PlaybackKpiService.ensure();
    PlaybackPolicyEngine.ensure();
  }

  void _showErrorStats() {
    final errorService = ErrorHandlingService.maybeFind();
    if (errorService != null) {
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
    final networkService = NetworkAwarenessService.maybeFind();
    if (networkService != null) {
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
    final uploadService = UploadQueueService.maybeFind();
    if (uploadService != null) {
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
    final draftService = DraftService.maybeFind();
    if (draftService != null) {
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
    final editingService = PostEditingService.maybeFind();
    if (editingService != null) {
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
    final mediaService = MediaEnhancementService.maybeFind();
    if (mediaService != null) {
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
