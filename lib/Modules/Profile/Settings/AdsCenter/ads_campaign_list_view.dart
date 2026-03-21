import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_campaign_editor_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

class AdsCampaignListView extends StatelessWidget {
  const AdsCampaignListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdsCenterController.ensure();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: Obx(() {
                  return DropdownButtonFormField<AdCampaignStatus?>(
                    initialValue: controller.filterStatus.value,
                    decoration: _decoration('ads_center.status'.tr),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text('common.all'.tr)),
                      ...AdCampaignStatus.values.map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => controller.applyFilters(
                      status: v,
                      clearStatus: v == null,
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
                      DropdownMenuItem(
                          value: null, child: Text('common.all'.tr)),
                      ...AdPlacementType.values.map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => controller.applyFilters(
                      placement: v,
                      clearPlacement: v == null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Obx(() {
                return Checkbox(
                  value: controller.filterIncludeTest.value,
                  onChanged: (v) {
                    controller.applyFilters(includeTest: v ?? true);
                  },
                );
              }),
              Text(
                'ads_center.include_test_campaigns'.tr,
                style: TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => const AdsCampaignEditorView());
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'ads_center.new_campaign'.tr,
                  style: TextStyle(fontFamily: 'MontserratMedium'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Obx(() {
            final list = controller.campaigns;
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'ads_center.no_campaigns'.tr,
                  style: TextStyle(fontFamily: 'MontserratMedium'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = list[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    title: Text(
                      c.name.isEmpty
                          ? 'ads_center.untitled_campaign'.tr
                          : c.name,
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
                            '${'ads_center.status'.tr}: ${c.status.name} • ${'ads_center.bid'.tr}: ${c.bidType.name} ${c.bidAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontFamily: 'MontserratMedium', fontSize: 12),
                          ),
                          Text(
                            '${'ads_center.placement'.tr}: ${c.placementTypes.map((e) => e.name).join(', ')}',
                            style: const TextStyle(
                                fontFamily: 'MontserratMedium', fontSize: 12),
                          ),
                          Text(
                            '${'ads_center.budget'.tr}: ${'ads_center.total'.tr} ${c.totalBudget.toStringAsFixed(2)} / ${'ads_center.daily'.tr} ${c.dailyBudget.toStringAsFixed(2)} / ${'ads_center.spent'.tr} ${c.spentAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontFamily: 'MontserratMedium', fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          Get.to(
                              () => AdsCampaignEditorView(initialCampaign: c));
                        } else if (v == 'activate') {
                          await controller.updateCampaignStatus(
                              c.id, AdCampaignStatus.active);
                        } else if (v == 'pause') {
                          await controller.updateCampaignStatus(
                              c.id, AdCampaignStatus.paused);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit', child: Text('profile.edit'.tr)),
                        PopupMenuItem(
                            value: 'activate',
                            child: Text('ads_center.activate'.tr)),
                        PopupMenuItem(
                            value: 'pause', child: Text('ads_center.pause'.tr)),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
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
