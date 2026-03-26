part of 'flood_listing_controller.dart';

FloodListingController ensureFloodListingController() =>
    maybeFindFloodListingController() ?? Get.put(FloodListingController());

FloodListingController? maybeFindFloodListingController() =>
    Get.isRegistered<FloodListingController>()
        ? Get.find<FloodListingController>()
        : null;
