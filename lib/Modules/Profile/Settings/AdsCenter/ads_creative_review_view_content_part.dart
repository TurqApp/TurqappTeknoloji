part of 'ads_creative_review_view.dart';

extension AdsCreativeReviewViewContentPart on AdsCreativeReviewView {
  Widget _buildPage(BuildContext context, AdsCenterController controller) {
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
}
