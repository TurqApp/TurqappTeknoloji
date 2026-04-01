import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ads_admin_guard.dart';
import 'package:turqappv2/Core/Services/Ads/ads_analytics_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_delivery_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_repository_service.dart';
import 'package:turqappv2/Core/Services/Ads/ads_targeting_service.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_application_service.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_utils.dart';

part 'ads_center_controller_actions_part.dart';
part 'ads_center_controller_base_part.dart';
part 'ads_center_controller_fields_part.dart';
part 'ads_center_controller_runtime_part.dart';
part 'ads_center_controller_stream_part.dart';

class AdsCenterController extends _AdsCenterControllerBase {
  AdsCenterController({
    super.repository,
    super.deliveryService,
    super.targetingService,
    super.analyticsService,
    super.applicationService,
  });
}

AdsCenterController ensureAdsCenterController({bool permanent = false}) =>
    maybeFindAdsCenterController() ??
    Get.put(AdsCenterController(), permanent: permanent);

AdsCenterController? maybeFindAdsCenterController() =>
    Get.isRegistered<AdsCenterController>()
        ? Get.find<AdsCenterController>()
        : null;
