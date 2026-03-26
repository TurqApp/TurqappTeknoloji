part of 'tests_controller.dart';

TestsController ensureTestsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindTestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TestsController(),
    tag: tag,
    permanent: permanent,
  );
}

TestsController? maybeFindTestsController({String? tag}) {
  final isRegistered = Get.isRegistered<TestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TestsController>(tag: tag);
}
