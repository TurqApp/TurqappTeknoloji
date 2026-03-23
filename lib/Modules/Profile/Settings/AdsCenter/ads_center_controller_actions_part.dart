part of 'ads_center_controller.dart';

extension AdsCenterControllerActionsPart on AdsCenterController {
  Future<String> saveCampaign(AdCampaign campaign) async {
    final id = await repository.upsertCampaign(campaign);
    await refreshDashboard();
    return id;
  }

  Future<String> saveCreative(AdCreative creative) async {
    final id = await repository.upsertCreative(creative);
    return id;
  }

  Future<void> reviewCreative({
    required String creativeId,
    required AdModerationStatus status,
    required String note,
  }) async {
    await repository.reviewCreative(
      creativeId,
      status: status,
      note: note,
    );
  }

  Future<void> updateCampaignStatus(
    String campaignId,
    AdCampaignStatus status,
  ) async {
    await repository.updateCampaignStatus(campaignId, status);
    await refreshDashboard();
  }

  Future<void> saveFlags(AdFeatureFlags flags) async {
    await AdsFeatureFlagsService.to.setFlags(flags);
  }

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
