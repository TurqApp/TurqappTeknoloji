part of 'ads_center_controller.dart';

class AdsCenterController extends GetxController {
  final _AdsCenterControllerState _state;
  AdsCenterController({
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
