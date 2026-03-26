part of 'about_profile_controller.dart';

AboutProfileController ensureAboutProfileController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindAboutProfileController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    AboutProfileController(),
    tag: tag,
    permanent: permanent,
  );
}

AboutProfileController? maybeFindAboutProfileController({String? tag}) {
  final isRegistered = Get.isRegistered<AboutProfileController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<AboutProfileController>(tag: tag);
}
