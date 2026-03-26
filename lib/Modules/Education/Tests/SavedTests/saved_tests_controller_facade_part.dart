part of 'saved_tests_controller.dart';

SavedTestsController ensureSavedTestsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSavedTestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SavedTestsController(),
    tag: tag,
    permanent: permanent,
  );
}

SavedTestsController? maybeFindSavedTestsController({String? tag}) {
  final isRegistered = Get.isRegistered<SavedTestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SavedTestsController>(tag: tag);
}
