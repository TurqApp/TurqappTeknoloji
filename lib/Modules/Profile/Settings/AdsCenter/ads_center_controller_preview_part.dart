part of 'ads_center_controller.dart';

extension AdsCenterControllerPreviewPart on AdsCenterController {
  Future<void> runPreview({
    required AdPlacementType placement,
    required String country,
    required String city,
    required int? age,
    required String userId,
  }) async {
    previewLoading.value = true;
    try {
      final ctx = await targetingService.buildContext(
        userId: userId,
        placement: placement,
        isPreview: true,
        country: country,
        city: city,
        age: age,
      );

      final res = await deliveryService.simulateForAdmin(ctx);
      previewResult.value = res;
    } finally {
      previewLoading.value = false;
    }
  }

  Future<void> trackPreviewImpression() async {
    final result = previewResult.value;
    if (!result.hasAd || result.campaign == null || result.creative == null) {
      return;
    }
    await analyticsService.logImpression(
      campaignId: result.campaign!.id,
      creativeId: result.creative!.id,
      placement: result.campaign!.placementTypes.first,
      isPreview: true,
    );
  }
}
