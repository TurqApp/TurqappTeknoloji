part of 'ads_center_controller_library.dart';

AdsCenterController ensureAdsCenterController({bool permanent = false}) {
  final existing = maybeFindAdsCenterController();
  if (existing != null) return existing;
  return Get.put(
    AdsCenterController(),
    permanent: permanent,
  );
}

AdsCenterController? maybeFindAdsCenterController() {
  final isRegistered = Get.isRegistered<AdsCenterController>();
  if (!isRegistered) return null;
  return Get.find<AdsCenterController>();
}
