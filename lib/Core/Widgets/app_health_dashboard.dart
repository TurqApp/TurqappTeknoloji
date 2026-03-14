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
import '../Services/SegmentCache/cache_manager.dart';
import '../Services/SegmentCache/cache_metrics.dart';

class AppHealthDashboard extends StatelessWidget {
  const AppHealthDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    _ensureDashboardServices();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Sağlık Paneli'),
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
    final profile = Get.isRegistered<StorageBudgetManager>()
        ? Get.find<StorageBudgetManager>().currentProfile
        : StorageBudgetManager.profileForPlanGb(3);
    final policy = Get.isRegistered<PlaybackPolicyEngine>()
        ? Get.find<PlaybackPolicyEngine>().snapshot()
        : null;
    final recentEvents = Get.isRegistered<PlaybackKpiService>()
        ? Get.find<PlaybackKpiService>().recentEvents
        : const <PlaybackKpiEvent>[];
    final lastEvent = recentEvents.isNotEmpty ? recentEvents.last : null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Playback Intelligence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Plan: ${profile.planGb} GB'),
            Text('Medya: ${CacheMetrics.formatBytes(profile.mediaQuotaBytes)}'),
            Text(
                'Gorsel: ${CacheMetrics.formatBytes(profile.imageQuotaBytes)}'),
            Text(
              'Metadata: ${CacheMetrics.formatBytes(profile.metadataQuotaBytes)}',
            ),
            Text(
              'Soft/Hard stop: '
              '${CacheMetrics.formatBytes(profile.streamCacheSoftStopBytes)} / '
              '${CacheMetrics.formatBytes(profile.streamCacheHardStopBytes)}',
            ),
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
            statusText = 'Mükemmel';
            statusDescription = 'Tüm sistemler stabil çalışıyor';
            break;
          case 'fair':
            statusColor = Colors.orange;
            statusIcon = Icons.warning;
            statusText = 'İyi';
            statusDescription = 'Küçük sorunlar tespit edildi';
            break;
          case 'poor':
            statusColor = Colors.red;
            statusIcon = Icons.error;
            statusText = 'Dikkat Gerekli';
            statusDescription = 'Birden fazla sorun müdahale bekliyor';
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
            statusText = 'Bilinmiyor';
            statusDescription = 'Sistem durumu okunamadı';
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
                      'Son 30dk Hata',
                      '${health['recentErrors']}',
                      Icons.bug_report,
                      (health['recentErrors'] as int) > 5
                          ? Colors.orange
                          : Colors.green,
                    ),
                    _buildMetric(
                      'Bağlantı',
                      (health['isOnline'] as bool) ? 'Çevrimiçi' : 'Çevrimdışı',
                      Icons.wifi,
                      (health['isOnline'] as bool) ? Colors.blue : Colors.red,
                    ),
                    _buildMetric(
                      'Kritik',
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
        const Text(
          'Servis Durumu',
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
              'Hata Yönetimi',
              _errorStatusLabel(errorStatus),
              Icons.security,
              _errorStatusColor(errorStatus),
              () => _showErrorStats(),
            ),
            _buildServiceCard(
              'Ağ Farkındalığı',
              (networkStats['currentNetwork'] ?? 'Bilinmiyor').toString(),
              Icons.network_check,
              (networkStats['isConnected'] as bool? ?? false)
                  ? Colors.blue
                  : Colors.red,
              () => _showNetworkStats(),
            ),
            _buildServiceCard(
              'Yükleme Kuyruğu',
              uploadBekliyor > 0 ? '$uploadBekliyor Bekliyor' : 'Boşta',
              Icons.cloud_upload,
              uploadBekliyor > 0 ? Colors.orange : Colors.green,
              () => _showUploadStats(),
            ),
            _buildServiceCard(
              'Otomatik Kayıt',
              '$draftTotal Taslak',
              Icons.save,
              Colors.teal,
              () => _showDraftStats(),
            ),
            _buildServiceCard(
              'Akıllı Düzenleme',
              canUndo ? 'Geri Al Hazır' : 'Beklemede',
              Icons.edit_note,
              Colors.purple,
              () => _showEditingStats(),
            ),
            _buildServiceCard(
              'Medya İyileştirme',
              mediaProcessing ? 'İşleniyor' : 'Boşta',
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

    final alerts = <String>[];
    if (dataUsagePercent >= 85) alerts.add('Veri kullanımı kritik eşikte');
    if (criticalErrors > 0) alerts.add('Kritik hata kaydı var');
    if (pendingUploads >= 5) alerts.add('Yükleme kuyruğu yoğun');
    if (cacheHitRate < 0.60) alerts.add('Cache hit oranı düşük');

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
              hasAlert ? 'KPI Alarm Durumu: Uyarı' : 'KPI Alarm Durumu: Normal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: hasAlert ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text('Cache Hit: ${(cacheHitRate * 100).toStringAsFixed(1)}%'),
            Text('Veri Kullanımı: ${dataUsagePercent.toStringAsFixed(1)}%'),
            Text('Kritik Hata: $criticalErrors'),
            Text('Bekleyen Upload: $pendingUploads'),
            const SizedBox(height: 8),
            Text(
              hasAlert ? alerts.join(' • ') : 'Tüm KPI değerleri eşik içinde.',
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
            const Text(
              'Performans Metrikleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildProgressIndicator(
                'Ağ Veri Kullanımı', dataUsagePercent, Colors.blue),
            _buildProgressIndicator(
                'Yükleme Kuyruk Yükü', queuePressure, Colors.orange),
            _buildProgressIndicator(
                'Kritik Hata Oranı', errorRatio, Colors.red),
            _buildProgressIndicator(
              'Medya İşleme İlerlemesi',
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
            const Text(
              'Kullanım İstatistikleri',
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
                    'Tamamlanan Yükleme',
                    '${uploadStats['completed'] ?? 0}',
                    Icons.cloud_done,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Medya Düzenleme',
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
                    'Kaydedilen Taslak',
                    '${draftStats['total'] ?? 0}',
                    Icons.drafts,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'İşlenen Hata',
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
                    'Son Düzenleme İşlemi',
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
        return 'Sağlıklı';
      case 'fair':
        return 'Orta';
      case 'poor':
        return 'Riskli';
      default:
        return 'Bilinmiyor';
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
          title: const Text('Hata Yönetimi İstatistikleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam Hata: ${stats['total']}'),
              Text('Kritik: ${stats['critical']}'),
              Text('Son 24 Saat: ${stats['last24Hours']}'),
              Text('Son 1 Hafta: ${stats['lastWeek']}'),
              Text('Tekrar Denenebilir: ${stats['retryableErrors']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Kapat'),
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
          title: const Text('Ağ Farkındalığı İstatistikleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ağ: ${stats['currentNetwork']}'),
              Text('Bağlı: ${stats['isConnected']}'),
              Text(
                  'Veri Kullanımı: ${stats['dataUsagePercentage'].toStringAsFixed(1)}%'),
              Text('Aylık Kullanım: ${stats['monthlyUsageMB']} MB'),
              Text('Kalan: ${stats['remainingMB']} MB'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Kapat'),
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
          title: const Text('Yükleme Kuyruğu İstatistikleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam: ${stats['total']}'),
              Text('Bekliyor: ${stats['pending']}'),
              Text('Tamamlanan: ${stats['completed']}'),
              Text('Başarısız: ${stats['failed']}'),
              Text('İşleniyor: ${stats['processing']}'),
              Text('Duraklatıldı: ${stats['paused']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Kapat'),
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
          title: const Text('Taslak Servisi İstatistikleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam Taslak: ${stats['total']}'),
              Text('Bugün: ${stats['today']}'),
              Text('Bu Hafta: ${stats['thisWeek']}'),
              Text('Medyalı: ${stats['withMedia']}'),
              Text('Sadece Metin: ${stats['textOnly']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Kapat'),
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
          title: const Text('Düzenleme İstatistikleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam İşlem: ${stats['totalActions']}'),
              Text('Son İşlem: ${stats['recentActions']}'),
              Text('Geri Alınabilir: ${stats['canUndo']}'),
              Text('İleri Alınabilir: ${stats['canRedo']}'),
              Text('Öneri Sayısı: ${stats['suggestionsGenerated']}'),
              Text('Akıllı Öneri: ${stats['smartSuggestionsEnabled']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Kapat'),
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
          title: const Text('Medya İyileştirme İstatistikleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam Düzenleme: ${stats['totalEdits']}'),
              Text('Görsel Düzenleme: ${stats['imageEdits']}'),
              Text('Video Düzenleme: ${stats['videoEdits']}'),
              Text('İşleniyor: ${stats['isProcessing']}'),
              Text('Seçili Filtre: ${stats['selectedFilter']}'),
              Text('Düzenleme Var: ${stats['hasAdjustments']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    }
  }
}
