part of 'my_tests_controller.dart';

MyTestsController ensureMyTestsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyTestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyTestsController(),
    tag: tag,
    permanent: permanent,
  );
}

MyTestsController? maybeFindMyTestsController({String? tag}) {
  final isRegistered = Get.isRegistered<MyTestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyTestsController>(tag: tag);
}
