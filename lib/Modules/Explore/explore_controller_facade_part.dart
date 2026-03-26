part of 'explore_controller.dart';

ExploreController ensureExploreController() =>
    maybeFindExploreController() ?? Get.put(ExploreController());

ExploreController? maybeFindExploreController() =>
    Get.isRegistered<ExploreController>()
        ? Get.find<ExploreController>()
        : null;
