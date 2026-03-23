part of 'ads_campaign_list_view.dart';

extension AdsCampaignListViewFiltersPart on AdsCampaignListView {
  Widget _buildFilters(AdsCenterController controller) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              return DropdownButtonFormField<AdCampaignStatus?>(
                initialValue: controller.filterStatus.value,
                decoration: _decoration('ads_center.status'.tr),
                items: [
                  DropdownMenuItem(value: null, child: Text('common.all'.tr)),
                  ...AdCampaignStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.name),
                    ),
                  ),
                ],
                onChanged: (value) => controller.applyFilters(
                  status: value,
                  clearStatus: value == null,
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() {
              return DropdownButtonFormField<AdPlacementType?>(
                initialValue: controller.filterPlacement.value,
                decoration: _decoration('ads_center.placement'.tr),
                items: [
                  DropdownMenuItem(value: null, child: Text('common.all'.tr)),
                  ...AdPlacementType.values.map(
                    (placement) => DropdownMenuItem(
                      value: placement,
                      child: Text(placement.name),
                    ),
                  ),
                ],
                onChanged: (value) => controller.applyFilters(
                  placement: value,
                  clearPlacement: value == null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
