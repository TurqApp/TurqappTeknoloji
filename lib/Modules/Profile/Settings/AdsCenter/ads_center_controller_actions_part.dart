part of 'ads_center_controller_library.dart';

class AdsCenterControllerActionsPart {
  const AdsCenterControllerActionsPart(this.controller);

  final AdsCenterController controller;

  Future<String> saveCampaign(AdCampaign campaign) async {
    final result = await controller.applicationService.saveCampaign(campaign);
    controller.dashboard.assignAll(result.dashboardMetrics);
    controller.errorText.value = null;
    return result.campaignId;
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
    final dashboardMetrics = await controller.applicationService
        .updateCampaignStatus(campaignId, status);
    controller.dashboard.assignAll(dashboardMetrics);
    controller.errorText.value = null;
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
      controller.previewResult.value =
          await controller.applicationService.runPreview(
        placement: placement,
        country: country,
        city: city,
        age: age,
        userId: userId,
      );
    } finally {
      controller.previewLoading.value = false;
    }
  }

  Future<void> trackPreviewImpression() async {
    await controller.applicationService
        .trackPreviewImpression(controller.previewResult.value);
  }
}
