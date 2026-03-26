part of 'create_test_question_content_controller.dart';

class CreateTestQuestionContentController extends GetxController {
  static CreateTestQuestionContentController ensure({
    required TestReadinessModel model,
    required String testID,
    required int index,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
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

  static CreateTestQuestionContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<CreateTestQuestionContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateTestQuestionContentController>(tag: tag);
  }

  final TestReadinessModel model;
  final String testID;
  final int index;
  final selectedImage = Rx<File?>(null);
  final focunImage = ''.obs;
  final selection = 5.obs;
  final dogruCevap = ''.obs;
  final selections = ['A'].obs;
  final isLoading = false.obs;
  final isInvalid = false.obs;

  CreateTestQuestionContentController({
    required this.model,
    required this.testID,
    required this.index,
  });
}
