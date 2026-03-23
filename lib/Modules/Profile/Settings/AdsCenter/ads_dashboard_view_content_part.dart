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
}
