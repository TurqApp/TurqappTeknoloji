part of 'career_profile_controller.dart';

CareerProfileController ensureCareerProfileController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCareerProfileController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CareerProfileController(),
    tag: tag,
    permanent: permanent,
  );
}

CareerProfileController? maybeFindCareerProfileController({String? tag}) {
  final isRegistered = Get.isRegistered<CareerProfileController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CareerProfileController>(tag: tag);
}
