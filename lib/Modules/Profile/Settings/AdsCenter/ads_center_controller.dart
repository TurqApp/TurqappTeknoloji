import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ads_admin_guard.dart';
import 'package:turqappv2/Core/Services/Ads/ads_analytics_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_delivery_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_repository_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_targeting_service.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_utils.dart';

part 'ads_center_controller_stream_part.dart';
part 'ads_center_controller_actions_part.dart';
part 'ads_center_controller_runtime_part.dart';
part 'ads_center_controller_fields_part.dart';

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
