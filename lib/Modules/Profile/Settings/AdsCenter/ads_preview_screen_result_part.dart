part of 'ads_preview_screen.dart';

extension AdsPreviewScreenResultPart on _AdsPreviewScreenState {
  Widget _buildPreviewResult() {
    final result = _controller.previewResult.value;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.hasAd
                ? 'ads_center.eligible_ad_found'.tr
                : 'ads_center.no_eligible_ad'.tr,
            style: const TextStyle(fontFamily: 'MontserratBold', fontSize: 14),
          ),
          const SizedBox(height: 6),
          if (result.message.isNotEmpty)
            Text(
              result.message,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
              ),
            ),
          if (result.campaign != null) ...[
            const SizedBox(height: 8),
            Text(
              '${'ads_center.campaign'.tr}: ${result.campaign!.name} (${result.campaign!.id})',
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
              ),
            ),
          ],
          if (result.creative != null)
            Text(
              '${'ads_center.creative'.tr}: ${result.creative!.headline} (${result.creative!.id})',
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
              ),
            ),
          if (result.decisions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'ads_center.reasons'.tr,
              style: const TextStyle(
                fontFamily: 'MontserratBold',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...result.decisions.map((decision) {
              final reasons = decision.reasons.isEmpty
                  ? 'common.ok'.tr
                  : decision.reasons.map((reason) => reason.name).join(', ');
              return Text(
                '${decision.campaignId}: $reasons',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 11,
                  color: Colors.black87,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
