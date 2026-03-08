import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

class AdsDeliveryMonitorView extends StatelessWidget {
  const AdsDeliveryMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdsCenterController>();

    return Obx(() {
      final logs = controller.deliveryLogs;
      if (logs.isEmpty) {
        return const Center(
          child: Text(
            'Delivery log bulunamadı.',
            style: TextStyle(fontFamily: 'MontserratMedium'),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final l = logs[index];
          final decisions =
              (l['decisions'] is List) ? l['decisions'] as List : const [];
          final hasAd = l['hasAd'] == true;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
              color: hasAd
                  ? Colors.green.withValues(alpha: .05)
                  : Colors.orange.withValues(alpha: .05),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAd ? 'Eligible Ad Found' : 'No Eligible Ad',
                    style: const TextStyle(
                        fontFamily: 'MontserratBold', fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text('User: ${l['userId'] ?? ''}',
                      style: const TextStyle(
                          fontFamily: 'MontserratMedium', fontSize: 12)),
                  Text('Placement: ${l['placement'] ?? ''}',
                      style: const TextStyle(
                          fontFamily: 'MontserratMedium', fontSize: 12)),
                  Text(
                      'Geo: ${(l['country'] ?? '')}/${(l['city'] ?? '')} age:${l['age'] ?? '-'}',
                      style: const TextStyle(
                          fontFamily: 'MontserratMedium', fontSize: 12)),
                  Text('Campaign: ${l['selectedCampaignId'] ?? '-'}',
                      style: const TextStyle(
                          fontFamily: 'MontserratMedium', fontSize: 12)),
                  Text('Creative: ${l['selectedCreativeId'] ?? '-'}',
                      style: const TextStyle(
                          fontFamily: 'MontserratMedium', fontSize: 12)),
                  if (decisions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Karar Detayı',
                        style: TextStyle(
                            fontFamily: 'MontserratBold', fontSize: 12)),
                    const SizedBox(height: 4),
                    ...decisions.take(6).map((d) {
                      final row = (d is Map) ? d : const <String, dynamic>{};
                      final campaignId = row['campaignId'] ?? '';
                      final eligible = row['eligible'] == true;
                      final reasons = (row['reasons'] is List)
                          ? (row['reasons'] as List).join(', ')
                          : '-';
                      return Text(
                        '$campaignId • ${eligible ? 'ok' : 'reject'} • $reasons',
                        style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 11,
                            color: Colors.black87),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
