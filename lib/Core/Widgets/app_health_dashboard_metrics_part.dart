part of 'app_health_dashboard.dart';

extension _AppHealthDashboardMetricsPart on _AppHealthDashboardState {
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
    final errorService = maybeFindErrorHandlingService();
    if (errorService != null) {
      return errorService.getSystemHealth();
    }
    return {
      'status': 'unknown',
      'recentErrors': 0,
      'criticalErrors': 0,
      'isOnline': false,
    };
  }

  Map<String, dynamic> _getErrorStats() {
    final errorService = maybeFindErrorHandlingService();
    if (errorService != null) {
      return errorService.getErrorStats();
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
    final networkService = NetworkAwarenessService.maybeFind();
    if (networkService != null) {
      return networkService.getNetworkStats();
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
    final uploadService = UploadQueueService.maybeFind();
    if (uploadService != null) {
      return uploadService.getQueueStats();
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
    final draftService = DraftService.maybeFind();
    if (draftService != null) {
      return draftService.getDraftStats();
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
    final editingService = maybeFindPostEditingService();
    if (editingService != null) {
      return editingService.getEditStatistics();
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
    final mediaService = maybeFindMediaEnhancementService();
    if (mediaService != null) {
      return mediaService.getProcessingStats();
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
}
