part of 'create_test_question_content_controller_library.dart';

CreateTestQuestionContentController ensureCreateTestQuestionContentController({
  required TestReadinessModel model,
  required String testID,
  required int index,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateTestQuestionContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateTestQuestionContentController(
      model: model,
      testID: testID,
      index: index,
    ),
    tag: tag,
    permanent: permanent,
  );
}

CreateTestQuestionContentController?
    maybeFindCreateTestQuestionContentController({String? tag}) {
  final isRegistered =
      Get.isRegistered<CreateTestQuestionContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateTestQuestionContentController>(tag: tag);
}
