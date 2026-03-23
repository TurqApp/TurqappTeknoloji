part of 'ads_center_controller.dart';

extension AdsCenterControllerSubscriptionPart on AdsCenterController {
  void _bindCampaigns() {
    _campaignSub?.cancel();
    _campaignSub = repository
        .watchCampaigns(
          status: filterStatus.value,
          placement: filterPlacement.value,
          includeTest: filterIncludeTest.value,
        )
        .listen(
          campaigns.assignAll,
          onError: _onStreamError,
        );
  }

  void _onStreamError(Object error) {
    errorText.value = normalizeAdsCenterError(error);
  }
}
