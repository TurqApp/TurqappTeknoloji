part of 'ads_center_controller.dart';

extension AdsCenterControllerStreamPart on AdsCenterController {
  Future<void> refreshDashboard() async {
    if (!canAccess.value) return;
    try {
      final metrics = await repository.getDashboardMetrics();
      dashboard.assignAll(metrics);
      errorText.value = null;
    } catch (e) {
      errorText.value = normalizeAdsCenterError(e);
    }
  }

  Future<void> refreshAll() async {
    loading.value = true;
    await refreshDashboard();
    _bindCampaigns();
    loading.value = false;
  }

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
