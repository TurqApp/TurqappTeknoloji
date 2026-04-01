part of 'my_test_results_controller.dart';

MyTestResultsController ensureMyTestResultsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyTestResultsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyTestResultsController(),
    tag: tag,
    permanent: permanent,
  );
}

MyTestResultsController? maybeFindMyTestResultsController({String? tag}) {
  final isRegistered = Get.isRegistered<MyTestResultsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyTestResultsController>(tag: tag);
}
