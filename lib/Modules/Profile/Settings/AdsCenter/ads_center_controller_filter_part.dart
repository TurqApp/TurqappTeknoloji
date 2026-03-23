part of 'ads_center_controller.dart';

extension AdsCenterControllerFilterPart on AdsCenterController {
  void applyFilters({
    AdCampaignStatus? status,
    AdPlacementType? placement,
    bool? includeTest,
    bool clearStatus = false,
    bool clearPlacement = false,
  }) {
    if (clearStatus) {
      filterStatus.value = null;
    } else if (status != null) {
      filterStatus.value = status;
    }

    if (clearPlacement) {
      filterPlacement.value = null;
    } else if (placement != null) {
      filterPlacement.value = placement;
    }

    if (includeTest != null) {
      filterIncludeTest.value = includeTest;
    }

    _bindCampaigns();
  }
}
