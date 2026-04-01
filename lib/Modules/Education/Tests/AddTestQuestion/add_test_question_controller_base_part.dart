part of 'add_test_question_controller_library.dart';

abstract class _AddTestQuestionControllerBase extends GetxController {
  _AddTestQuestionControllerBase({
    required List<TestReadinessModel> initialSoruList,
    required String testID,
    required String testTuru,
    required Function onUpdate,
  }) : _state = _AddTestQuestionControllerState(
          initialSoruList: initialSoruList,
          testID: testID,
          testTuru: testTuru,
          onUpdate: onUpdate,
        );

  final _AddTestQuestionControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleAddTestQuestionControllerInit(this as AddTestQuestionController);
  }
}
