import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_campaign_editor_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

class AdsCampaignListView extends StatelessWidget {
  const AdsCampaignListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdsCenterController>();

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
                    decoration: _decoration('Status'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
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
                    decoration: _decoration('Placement'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
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
              const Text(
                'Test kampanyaları dahil',
                style: TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => const AdsCampaignEditorView());
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Yeni Kampanya',
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
              return const Center(
                child: Text(
                  'Kampanya bulunamadı.',
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
                      c.name.isEmpty ? '(isimsiz kampanya)' : c.name,
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
                            'Status: ${c.status.name} • Bid: ${c.bidType.name} ${c.bidAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontFamily: 'MontserratMedium', fontSize: 12),
                          ),
                          Text(
                            'Placement: ${c.placementTypes.map((e) => e.name).join(', ')}',
                            style: const TextStyle(
                                fontFamily: 'MontserratMedium', fontSize: 12),
                          ),
                          Text(
                            'Bütçe: total ${c.totalBudget.toStringAsFixed(2)} / daily ${c.dailyBudget.toStringAsFixed(2)} / spent ${c.spentAmount.toStringAsFixed(2)}',
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
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        PopupMenuItem(
                            value: 'activate', child: Text('Aktif Et')),
                        PopupMenuItem(value: 'pause', child: Text('Duraklat')),
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
