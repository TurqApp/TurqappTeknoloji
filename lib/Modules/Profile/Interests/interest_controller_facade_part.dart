part of 'interest_controller.dart';

InterestsController ensureInterestsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindInterestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    InterestsController(),
    tag: tag,
    permanent: permanent,
  );
}

InterestsController? maybeFindInterestsController({String? tag}) {
  final isRegistered = Get.isRegistered<InterestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<InterestsController>(tag: tag);
}
