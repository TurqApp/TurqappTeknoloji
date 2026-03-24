import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

class AdsDeliveryMonitorView extends StatelessWidget {
  const AdsDeliveryMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdsCenterController.ensure();
    return Obx(() {
      final logs = controller.deliveryLogs;
      if (logs.isEmpty) {
        return Center(
          child: Text(
            'ads_center.no_delivery_logs'.tr,
            style: const TextStyle(fontFamily: 'MontserratMedium'),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildLogCard(log);
        },
      );
    });
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final decisions =
        (log['decisions'] is List) ? log['decisions'] as List : const [];
    final hasAd = log['hasAd'] == true;
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
              hasAd
                  ? 'ads_center.eligible_ad_found'.tr
                  : 'ads_center.no_eligible_ad'.tr,
              style:
                  const TextStyle(fontFamily: 'MontserratBold', fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '${'ads_center.user_id'.tr}: ${log['userId'] ?? ''}',
              style:
                  const TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
            ),
            Text(
              '${'ads_center.placement'.tr}: ${log['placement'] ?? ''}',
              style:
                  const TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
            ),
            Text(
              '${'ads_center.geo'.tr}: ${(log['country'] ?? '')}/${(log['city'] ?? '')} ${'ads_center.age_short'.tr}:${log['age'] ?? '-'}',
              style:
                  const TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
            ),
            Text(
              '${'ads_center.campaign'.tr}: ${log['selectedCampaignId'] ?? '-'}',
              style:
                  const TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
            ),
            Text(
              '${'ads_center.creative'.tr}: ${log['selectedCreativeId'] ?? '-'}',
              style:
                  const TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
            ),
            if (decisions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ads_center.decision_detail'.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratBold',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ...decisions.take(6).map(_buildDecisionLine),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionLine(dynamic decision) {
    final row = (decision is Map) ? decision : const <String, dynamic>{};
    final campaignId = row['campaignId'] ?? '';
    final eligible = row['eligible'] == true;
    final reasons =
        (row['reasons'] is List) ? (row['reasons'] as List).join(', ') : '-';
    return Text(
      '$campaignId • ${eligible ? 'common.ok'.tr : normalizeLowercase('common.reject'.tr)} • $reasons',
      style: const TextStyle(
        fontFamily: 'MontserratMedium',
        fontSize: 11,
        color: Colors.black87,
      ),
    );
  }
}
