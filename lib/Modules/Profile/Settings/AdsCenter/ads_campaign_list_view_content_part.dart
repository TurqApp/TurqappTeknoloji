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

  Widget _buildCampaignTile({
    required AdsCenterController controller,
    required AdCampaign campaign,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: Text(
          campaign.name.isEmpty
              ? 'ads_center.untitled_campaign'.tr
              : campaign.name,
          style: const TextStyle(
            fontFamily: 'MontserratBold',
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'ads_center.status'.tr}: ${campaign.status.name} • ${'ads_center.bid'.tr}: ${campaign.bidType.name} ${campaign.bidAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                ),
              ),
              Text(
                '${'ads_center.placement'.tr}: ${campaign.placementTypes.map((placement) => placement.name).join(', ')}',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                ),
              ),
              Text(
                '${'ads_center.budget'.tr}: ${'ads_center.total'.tr} ${campaign.totalBudget.toStringAsFixed(2)} / ${'ads_center.daily'.tr} ${campaign.dailyBudget.toStringAsFixed(2)} / ${'ads_center.spent'.tr} ${campaign.spentAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Get.to(() => AdsCampaignEditorView(initialCampaign: campaign));
            } else if (value == 'activate') {
              await controller.updateCampaignStatus(
                campaign.id,
                AdCampaignStatus.active,
              );
            } else if (value == 'pause') {
              await controller.updateCampaignStatus(
                campaign.id,
                AdCampaignStatus.paused,
              );
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text('profile.edit'.tr)),
            PopupMenuItem(
              value: 'activate',
              child: Text('ads_center.activate'.tr),
            ),
            PopupMenuItem(
              value: 'pause',
              child: Text('ads_center.pause'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
