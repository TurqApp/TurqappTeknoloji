part of 'solve_test_controller.dart';

class SolveTestController extends GetxController {
  final _SolveTestControllerState _state;

  SolveTestController({
    required String testID,
    required Function showSucces,
  }) : _state = _SolveTestControllerState(
          testID: testID,
          showSucces: showSucces,
        );

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
