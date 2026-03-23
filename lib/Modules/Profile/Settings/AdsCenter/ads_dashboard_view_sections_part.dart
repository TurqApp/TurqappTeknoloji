part of 'ads_dashboard_view.dart';

extension AdsDashboardViewSectionsPart on AdsDashboardView {
  Widget _buildSummarySection(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ads_center.summary'.tr),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricCard(
              'ads_center.total_campaigns'.tr,
              '${metrics['totalCampaigns'] ?? 0}',
            ),
            _metricCard(
              'ads_center.active'.tr,
              '${metrics['activeCampaigns'] ?? 0}',
            ),
            _metricCard(
              'ads_center.paused'.tr,
              '${metrics['pausedCampaigns'] ?? 0}',
            ),
            _metricCard(
              'ads_center.impressions'.tr,
              '${metrics['totalImpressions'] ?? 0}',
            ),
            _metricCard(
              'ads_center.reach'.tr,
              '${metrics['uniqueReach'] ?? 0}',
            ),
            _metricCard(
              'ads_center.clicks'.tr,
              '${metrics['clicks'] ?? 0}',
            ),
            _metricCard('CTR', _percent(metrics['ctr'])),
            _metricCard(
              'ads_center.spend'.tr,
              _money(metrics['spend']),
            ),
            _metricCard(
              'ads_center.avg_cpc'.tr,
              _money(metrics['avgCpc']),
            ),
            _metricCard(
              'ads_center.avg_cpm'.tr,
              _money(metrics['avgCpm']),
            ),
            _metricCard(
              'ads_center.video_completion'.tr,
              _percent(metrics['videoCompletionRate']),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureFlagsSection({
    required AdsCenterController controller,
    required AdFeatureFlags flags,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ads_center.feature_flags'.tr),
        _flagTile(
          title: 'ads_center.flag_infrastructure'.tr,
          value: flags.adsInfrastructureEnabled,
          onChanged: (value) => _saveFlags(
            controller,
            flags.copyWith(adsInfrastructureEnabled: value),
          ),
        ),
        _flagTile(
          title: 'ads_center.flag_admin_panel'.tr,
          value: flags.adsAdminPanelEnabled,
          onChanged: (value) => _saveFlags(
            controller,
            flags.copyWith(adsAdminPanelEnabled: value),
          ),
        ),
        _flagTile(
          title: 'ads_center.flag_delivery'.tr,
          value: flags.adsDeliveryEnabled,
          onChanged: (value) => _saveFlags(
            controller,
            flags.copyWith(adsDeliveryEnabled: value),
          ),
        ),
        _flagTile(
          title: 'ads_center.flag_public_visibility'.tr,
          value: flags.adsPublicVisibilityEnabled,
          onChanged: (value) => _saveFlags(
            controller,
            flags.copyWith(adsPublicVisibilityEnabled: value),
          ),
        ),
        _flagTile(
          title: 'ads_center.flag_preview_mode'.tr,
          value: flags.adsPreviewModeEnabled,
          onChanged: (value) => _saveFlags(
            controller,
            flags.copyWith(adsPreviewModeEnabled: value),
          ),
        ),
      ],
    );
  }
}
