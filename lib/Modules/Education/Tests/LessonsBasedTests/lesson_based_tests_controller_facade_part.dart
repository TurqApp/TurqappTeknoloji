part of 'lesson_based_tests_controller.dart';

LessonBasedTestsController ensureLessonBasedTestsController(
  String testTuru, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindLessonBasedTestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    LessonBasedTestsController(testTuru),
    tag: tag,
    permanent: permanent,
  );
}

LessonBasedTestsController? maybeFindLessonBasedTestsController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<LessonBasedTestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<LessonBasedTestsController>(tag: tag);
}
