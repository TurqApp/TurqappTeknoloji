part of 'create_test_question_content_controller_library.dart';

class CreateTestQuestionContentController extends GetxController {
  final _CreateTestQuestionContentControllerState _state;

  CreateTestQuestionContentController({
    required TestReadinessModel model,
    required String testID,
    required int index,
  }) : _state = _CreateTestQuestionContentControllerState(
          model: model,
          testID: testID,
          index: index,
        );
}
