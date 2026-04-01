part of 'test_past_result_content_controller.dart';

TestPastResultContentController ensureTestPastResultContentController(
  TestsModel model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindTestPastResultContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TestPastResultContentController(model),
    tag: tag,
    permanent: permanent,
  );
}

TestPastResultContentController? maybeFindTestPastResultContentController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<TestPastResultContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TestPastResultContentController>(tag: tag);
}
