part of 'add_test_question_controller_library.dart';

AddTestQuestionController ensureAddTestQuestionController({
  required List<TestReadinessModel> initialSoruList,
  required String testID,
  required String testTuru,
  required Function onUpdate,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindAddTestQuestionController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    AddTestQuestionController(
      initialSoruList: initialSoruList,
      testID: testID,
      testTuru: testTuru,
      onUpdate: onUpdate,
    ),
    tag: tag,
    permanent: permanent,
  );
}

AddTestQuestionController? maybeFindAddTestQuestionController({String? tag}) {
  final isRegistered = Get.isRegistered<AddTestQuestionController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<AddTestQuestionController>(tag: tag);
}

void _handleAddTestQuestionControllerInit(
    AddTestQuestionController controller) {
  controller.soruList.assignAll(controller.initialSoruList);
  controller.getSorular();
}
