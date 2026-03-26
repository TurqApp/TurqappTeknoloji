part of 'create_test_controller.dart';

CreateTestController ensureCreateTestController(
  TestsModel? model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateTestController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateTestController(model),
    tag: tag,
    permanent: permanent,
  );
}

CreateTestController? maybeFindCreateTestController({String? tag}) {
  final isRegistered = Get.isRegistered<CreateTestController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateTestController>(tag: tag);
}
