import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Models/Ads/ad_feature_flags.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

class AdsDashboardView extends StatelessWidget {
  const AdsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdsCenterController>();
    final flagsService = AdsFeatureFlagsService.to;

    return RefreshIndicator(
      onRefresh: () async {
        await flagsService.refreshOnce();
        await controller.refreshDashboard();
      },
      child: Obx(() {
        final m = controller.dashboard;
        final flags = flagsService.flags.value;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          children: [
            _sectionTitle('Özet'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metricCard('Toplam Kampanya', '${m['totalCampaigns'] ?? 0}'),
                _metricCard('Aktif', '${m['activeCampaigns'] ?? 0}'),
                _metricCard('Duraklatıldı', '${m['pausedCampaigns'] ?? 0}'),
                _metricCard('Impression', '${m['totalImpressions'] ?? 0}'),
                _metricCard('Reach', '${m['uniqueReach'] ?? 0}'),
                _metricCard('Click', '${m['clicks'] ?? 0}'),
                _metricCard('CTR', _percent(m['ctr'])),
                _metricCard('Spend', _money(m['spend'])),
                _metricCard('Avg CPC', _money(m['avgCpc'])),
                _metricCard('Avg CPM', _money(m['avgCpm'])),
                _metricCard(
                    'Video Completion', _percent(m['videoCompletionRate'])),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle('Feature Flags'),
            _flagTile(
              title: 'adsInfrastructureEnabled',
              value: flags.adsInfrastructureEnabled,
              onChanged: (v) => _saveFlags(
                controller,
                flags.copyWith(adsInfrastructureEnabled: v),
              ),
            ),
            _flagTile(
              title: 'adsAdminPanelEnabled',
              value: flags.adsAdminPanelEnabled,
              onChanged: (v) => _saveFlags(
                controller,
                flags.copyWith(adsAdminPanelEnabled: v),
              ),
            ),
            _flagTile(
              title: 'adsDeliveryEnabled',
              value: flags.adsDeliveryEnabled,
              onChanged: (v) => _saveFlags(
                controller,
                flags.copyWith(adsDeliveryEnabled: v),
              ),
            ),
            _flagTile(
              title: 'adsPublicVisibilityEnabled',
              value: flags.adsPublicVisibilityEnabled,
              onChanged: (v) => _saveFlags(
                controller,
                flags.copyWith(adsPublicVisibilityEnabled: v),
              ),
            ),
            _flagTile(
              title: 'adsPreviewModeEnabled',
              value: flags.adsPreviewModeEnabled,
              onChanged: (v) => _saveFlags(
                controller,
                flags.copyWith(adsPreviewModeEnabled: v),
              ),
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
    final n = (raw is num) ? raw.toDouble() : 0;
    return '${n.toStringAsFixed(2)} TRY';
  }

  String _percent(dynamic raw) {
    final n = (raw is num) ? raw.toDouble() : 0;
    return '%${n.toStringAsFixed(2)}';
  }
}
