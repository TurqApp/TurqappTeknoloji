part of 'ads_center_controller.dart';

abstract class _AdsCenterControllerBase extends GetxController {
  _AdsCenterControllerBase({
    AdsRepositoryService? repository,
    AdsDeliveryService? deliveryService,
    AdsTargetingService? targetingService,
    AdsAnalyticsService? analyticsService,
  }) : _state = _AdsCenterControllerState(
          repository: repository,
          deliveryService: deliveryService,
          targetingService: targetingService,
          analyticsService: analyticsService,
        );

  final _AdsCenterControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleRuntimeInit();
  }

  @override
  void onClose() {
    _handleRuntimeClose();
    super.onClose();
  }
}
