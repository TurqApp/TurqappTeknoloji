import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_campaign_editor_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

part 'ads_campaign_list_view_tile_part.dart';

class AdsCampaignListView extends StatelessWidget {
  const AdsCampaignListView({super.key});

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

  @override
  Widget build(BuildContext context) {
    final controller = AdsCenterController.ensure();
    return _buildPage(controller);
  }
}
