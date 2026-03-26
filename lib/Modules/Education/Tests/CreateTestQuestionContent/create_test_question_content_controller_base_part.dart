part of 'create_test_question_content_controller_library.dart';

abstract class _CreateTestQuestionContentControllerBase extends GetxController {
  _CreateTestQuestionContentControllerBase({
    required TestReadinessModel model,
    required String testID,
    required int index,
  }) : _state = _CreateTestQuestionContentControllerState(
          model: model,
          testID: testID,
          index: index,
        );

  final _CreateTestQuestionContentControllerState _state;
}
