part of 'ads_center_controller.dart';

class AdsCenterController extends GetxController {
  static AdsCenterController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      AdsCenterController(),
      permanent: permanent,
    );
  }

  static AdsCenterController? maybeFind() {
    final isRegistered = Get.isRegistered<AdsCenterController>();
    if (!isRegistered) return null;
    return Get.find<AdsCenterController>();
  }

  final AdsRepositoryService repository;
  final AdsDeliveryService deliveryService;
  final AdsTargetingService targetingService;
  final AdsAnalyticsService analyticsService;

  AdsCenterController({
    AdsRepositoryService? repository,
    AdsDeliveryService? deliveryService,
    AdsTargetingService? targetingService,
    AdsAnalyticsService? analyticsService,
  })  : repository = repository ?? const AdsRepositoryService(),
        deliveryService = deliveryService ?? AdsDeliveryService(),
        targetingService = targetingService ?? const AdsTargetingService(),
        analyticsService = analyticsService ?? const AdsAnalyticsService();
  final _state = _AdsCenterControllerState();

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
