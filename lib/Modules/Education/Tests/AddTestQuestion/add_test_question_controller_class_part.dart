part of 'add_test_question_controller.dart';

class AddTestQuestionController extends GetxController {
  final _AddTestQuestionControllerState _state;

  AddTestQuestionController({
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

  @override
  void onInit() {
    super.onInit();
    _handleAddTestQuestionControllerInit(this);
  }
}
