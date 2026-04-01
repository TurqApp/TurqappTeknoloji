part of 'ads_center_controller_library.dart';

extension AdsCenterControllerRuntimePart on AdsCenterController {
  void _handleRuntimeInit() {
    unawaited(_init());
  }

  void _handleRuntimeClose() {
    _campaignSub?.cancel();
    _creativeSub?.cancel();
    _advertiserSub?.cancel();
    _statsSub?.cancel();
    _logSub?.cancel();
  }

  Future<String> saveCampaign(AdCampaign campaign) =>
      AdsCenterControllerActionsPart(this).saveCampaign(campaign);

  Future<String> saveCreative(AdCreative creative) =>
      AdsCenterControllerActionsPart(this).saveCreative(creative);

  Future<void> reviewCreative({
    required String creativeId,
    required AdModerationStatus status,
    required String note,
  }) =>
      AdsCenterControllerActionsPart(this).reviewCreative(
        creativeId: creativeId,
        status: status,
        note: note,
      );

  Future<void> updateCampaignStatus(
    String campaignId,
    AdCampaignStatus status,
  ) =>
      AdsCenterControllerActionsPart(this).updateCampaignStatus(
        campaignId,
        status,
      );

  Future<void> saveFlags(AdFeatureFlags flags) =>
      AdsCenterControllerActionsPart(this).saveFlags(flags);

  Future<void> runPreview({
    required AdPlacementType placement,
    required String country,
    required String city,
    required int? age,
    required String userId,
  }) =>
      AdsCenterControllerActionsPart(this).runPreview(
        placement: placement,
        country: country,
        city: city,
        age: age,
        userId: userId,
      );

  Future<void> trackPreviewImpression() =>
      AdsCenterControllerActionsPart(this).trackPreviewImpression();
}
