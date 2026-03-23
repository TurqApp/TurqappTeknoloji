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
}
