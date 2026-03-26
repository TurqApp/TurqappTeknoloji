import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

class AdsCreativeReviewView extends StatelessWidget {
  const AdsCreativeReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ensureAdsCenterController();
    return Obx(() {
      final creatives = controller.creatives;
      if (creatives.isEmpty) {
        return Center(
          child: Text(
            'ads_center.no_creatives'.tr,
            style: const TextStyle(fontFamily: 'MontserratMedium'),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: creatives.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final creative = creatives[index];
          return _buildCreativeCard(
            context: context,
            controller: controller,
            creative: creative,
          );
        },
      );
    });
  }

  Widget _buildCreativeCard({
    required BuildContext context,
    required AdsCenterController controller,
    required AdCreative creative,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              creative.headline.isEmpty
                  ? 'ads_center.untitled_creative'.tr
                  : creative.headline,
              style: const TextStyle(
                fontFamily: 'MontserratBold',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${'ads_center.type'.tr}: ${creative.type.name} • ${'ads_center.moderation'.tr}: ${creative.moderationStatus.name}',
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
              ),
            ),
            Text(
              '${'ads_center.campaign'.tr}: ${creative.campaignId} • ${'ads_center.duration'.tr}: ${creative.durationSec}s',
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
              ),
            ),
            if (creative.mediaURL.isNotEmpty)
              Text(
                '${'ads_center.media'.tr}: ${creative.mediaURL}',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                ),
              ),
            if (creative.hlsMasterURL.isNotEmpty)
              Text(
                'HLS: ${creative.hlsMasterURL}',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final note = await _askNote(
                        context,
                        title: 'ads_center.reject_note'.tr,
                      );
                      if (note == null) return;
                      await controller.reviewCreative(
                        creativeId: creative.id,
                        status: AdModerationStatus.rejected,
                        note: note,
                      );
                    },
                    child: Text('common.reject'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final note = await _askNote(
                        context,
                        title: 'ads_center.approve_note'.tr,
                      );
                      if (note == null) return;
                      await controller.reviewCreative(
                        creativeId: creative.id,
                        status: AdModerationStatus.approved,
                        note: note,
                      );
                    },
                    child: Text('common.approve'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askNote(
    BuildContext context, {
    required String title,
  }) async {
    final controller = TextEditingController();
    final output = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'ads_center.review_note_hint'.tr,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text('common.save'.tr),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return output;
  }
}
