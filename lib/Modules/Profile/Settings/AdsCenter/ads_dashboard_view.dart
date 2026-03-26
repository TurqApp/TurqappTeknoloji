import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Models/Ads/ad_feature_flags.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

part 'ads_dashboard_view_sections_part.dart';

class AdsDashboardView extends StatelessWidget {
  const AdsDashboardView({super.key});

  Widget _buildPage({
    required AdsCenterController controller,
    required AdsFeatureFlagsService flagsService,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        await flagsService.refreshOnce();
        await controller.refreshDashboard();
      },
      child: Obx(() {
        final metrics = controller.dashboard;
        final flags = flagsService.flags.value;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          children: [
            _buildSummarySection(metrics),
            const SizedBox(height: 16),
            _buildFeatureFlagsSection(
              controller: controller,
              flags: flags,
            ),
          ],
        );
      }),
    );
  }

  Future<void> _saveFlags(
    AdsCenterController controller,
    AdFeatureFlags flags,
  ) async {
    await controller.saveFlags(flags);
    await controller.refreshDashboard();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'MontserratBold',
          fontSize: 15,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: SwitchListTile.adaptive(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 13,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  String _money(dynamic raw) {
    final number = (raw is num) ? raw.toDouble() : 0;
    return '${number.toStringAsFixed(2)} TRY';
  }

  String _percent(dynamic raw) {
    final number = (raw is num) ? raw.toDouble() : 0;
    return '%${number.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = ensureAdsCenterController();
    final flagsService = AdsFeatureFlagsService.to;
    return _buildPage(
      controller: controller,
      flagsService: flagsService,
    );
  }
}
