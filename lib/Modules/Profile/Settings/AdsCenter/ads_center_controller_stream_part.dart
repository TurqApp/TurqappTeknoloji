part of 'ads_center_controller.dart';

extension AdsCenterControllerStreamPart on AdsCenterController {
  Future<void> _init() async {
    loading.value = true;
    errorText.value = null;
    try {
      canAccess.value = await AdsAdminGuard.canAccessAdsCenter();
      if (!canAccess.value) {
        return;
      }

      await AdsFeatureFlagsService.ensure().init();

      _bindCampaigns();
      _creativeSub = repository.watchCreatives().listen(
            creatives.assignAll,
            onError: _onStreamError,
          );
      _advertiserSub = repository.watchAdvertisers().listen(
            advertisers.assignAll,
            onError: _onStreamError,
          );
      _statsSub = repository.watchDailyStats().listen(
            dailyStats.assignAll,
            onError: _onStreamError,
          );
      _logSub = repository.watchDeliveryLogs().listen(
            deliveryLogs.assignAll,
            onError: _onStreamError,
          );

      await refreshDashboard();
    } catch (e) {
      errorText.value = normalizeAdsCenterError(e);
    } finally {
      loading.value = false;
    }
  }
}
