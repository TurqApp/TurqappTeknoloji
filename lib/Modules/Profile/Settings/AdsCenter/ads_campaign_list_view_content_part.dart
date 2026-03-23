part of 'ads_campaign_list_view.dart';

extension AdsCampaignListViewContentPart on AdsCampaignListView {
  Widget _buildPage(AdsCenterController controller) {
    return Column(
      children: [
        _buildFilters(controller),
        _buildActionsRow(controller),
        const SizedBox(height: 4),
        Expanded(
          child: Obx(() {
            final campaigns = controller.campaigns;
            if (campaigns.isEmpty) {
              return Center(
                child: Text(
                  'ads_center.no_campaigns'.tr,
                  style: const TextStyle(fontFamily: 'MontserratMedium'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: campaigns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                return _buildCampaignTile(
                  controller: controller,
                  campaign: campaign,
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
