part of 'ads_dashboard_view.dart';

extension AdsDashboardViewContentPart on AdsDashboardView {
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
            const SizedBox(height: 16),
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
}
