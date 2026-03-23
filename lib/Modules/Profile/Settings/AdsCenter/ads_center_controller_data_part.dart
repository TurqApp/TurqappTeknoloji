part of 'ads_center_controller.dart';

extension AdsCenterControllerDataPart on AdsCenterController {
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
}
