part of 'ads_creative_review_view.dart';

extension AdsCreativeReviewViewTilePart on AdsCreativeReviewView {
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
}
