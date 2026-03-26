part of 'ads_center_controller_library.dart';

class AdsCenterControllerActionsPart {
  const AdsCenterControllerActionsPart(this.controller);

  final AdsCenterController controller;

  Future<String> saveCampaign(AdCampaign campaign) async {
    final id = await controller.repository.upsertCampaign(campaign);
    await controller.refreshDashboard();
    return id;
  }

  Future<String> saveCreative(AdCreative creative) async {
    final id = await controller.repository.upsertCreative(creative);
    return id;
  }

  Future<void> reviewCreative({
    required String creativeId,
    required AdModerationStatus status,
    required String note,
  }) async {
    await controller.repository.reviewCreative(
      creativeId,
      status: status,
      note: note,
    );
  }

  Future<void> updateCampaignStatus(
    String campaignId,
    AdCampaignStatus status,
  ) async {
    await controller.repository.updateCampaignStatus(campaignId, status);
    await controller.refreshDashboard();
  }

  Future<void> saveFlags(AdFeatureFlags flags) async {
    await ensureAdsFeatureFlagsService().setFlags(flags);
  }

  Future<void> runPreview({
    required AdPlacementType placement,
    required String country,
    required String city,
    required int? age,
    required String userId,
  }) async {
    controller.previewLoading.value = true;
    try {
      final ctx = await controller.targetingService.buildContext(
        userId: userId,
        placement: placement,
        isPreview: true,
        country: country,
        city: city,
        age: age,
      );

      final res = await controller.deliveryService.simulateForAdmin(ctx);
      controller.previewResult.value = res;
    } finally {
      controller.previewLoading.value = false;
    }
  }

  Future<void> trackPreviewImpression() async {
    final result = controller.previewResult.value;
    if (!result.hasAd || result.campaign == null || result.creative == null) {
      return;
    }
    await controller.analyticsService.logImpression(
      campaignId: result.campaign!.id,
      creativeId: result.creative!.id,
      placement: result.campaign!.placementTypes.first,
      isPreview: true,
    );
  }
}
