part of 'ads_center_controller_library.dart';

AdsCenterController ensureAdsCenterController({bool permanent = false}) =>
    maybeFindAdsCenterController() ??
    Get.put(AdsCenterController(), permanent: permanent);

AdsCenterController? maybeFindAdsCenterController() =>
    Get.isRegistered<AdsCenterController>()
        ? Get.find<AdsCenterController>()
        : null;
