part of 'my_past_test_results_preview_controller.dart';

MyPastTestResultsPreviewController ensureMyPastTestResultsPreviewController(
  TestsModel model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyPastTestResultsPreviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyPastTestResultsPreviewController(model),
    tag: tag,
    permanent: permanent,
  );
}

MyPastTestResultsPreviewController?
    maybeFindMyPastTestResultsPreviewController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<MyPastTestResultsPreviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyPastTestResultsPreviewController>(tag: tag);
}
