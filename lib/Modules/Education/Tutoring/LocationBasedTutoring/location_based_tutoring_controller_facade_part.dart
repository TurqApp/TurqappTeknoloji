part of 'location_based_tutoring_controller.dart';

LocationBasedTutoringController ensureLocationBasedTutoringController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindLocationBasedTutoringController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    LocationBasedTutoringController(),
    tag: tag,
    permanent: permanent,
  );
}

LocationBasedTutoringController? maybeFindLocationBasedTutoringController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<LocationBasedTutoringController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<LocationBasedTutoringController>(tag: tag);
}

extension LocationBasedTutoringControllerFacadePart
    on LocationBasedTutoringController {
  Future<void> fetchLocationBasedTutoring({
    bool silent = false,
  }) =>
      _LocationBasedTutoringControllerRuntimeX(this)
          .fetchLocationBasedTutoring(silent: silent);
}
