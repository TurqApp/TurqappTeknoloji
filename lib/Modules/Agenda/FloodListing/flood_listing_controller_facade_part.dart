part of 'flood_listing_controller.dart';

FloodListingController ensureFloodListingController() {
  final existing = maybeFindFloodListingController();
  if (existing != null) return existing;
  return Get.put(FloodListingController());
}

FloodListingController? maybeFindFloodListingController() {
  final isRegistered = Get.isRegistered<FloodListingController>();
  if (!isRegistered) return null;
  return Get.find<FloodListingController>();
}
