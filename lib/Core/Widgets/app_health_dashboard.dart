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

part 'app_health_dashboard_cards_part.dart';
part 'app_health_dashboard_metrics_part.dart';
part 'app_health_dashboard_dialogs_part.dart';

class AppHealthDashboard extends StatefulWidget {
  const AppHealthDashboard({super.key});

  @override
  State<AppHealthDashboard> createState() => _AppHealthDashboardState();
}

class _AppHealthDashboardState extends State<AppHealthDashboard> {
  @override
  void initState() {
    super.initState();
    _ensureDashboardServices();
  }

  @override
  Widget build(BuildContext context) {
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
}
