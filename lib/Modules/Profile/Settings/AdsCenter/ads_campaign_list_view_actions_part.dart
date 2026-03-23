part of 'ads_campaign_list_view.dart';

extension AdsCampaignListViewActionsPart on AdsCampaignListView {
  Widget _buildActionsRow(AdsCenterController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Obx(() {
            return Checkbox(
              value: controller.filterIncludeTest.value,
              onChanged: (value) {
                controller.applyFilters(includeTest: value ?? true);
              },
            );
          }),
          Text(
            'ads_center.include_test_campaigns'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Get.to(() => const AdsCampaignEditorView());
            },
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              'ads_center.new_campaign'.tr,
              style: const TextStyle(fontFamily: 'MontserratMedium'),
            ),
          ),
        ],
      ),
    );
  }
}
