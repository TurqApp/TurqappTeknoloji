part of 'solve_test_controller.dart';

class SolveTestController extends _SolveTestControllerBase {
  SolveTestController({
    required String testID,
    required Function showSucces,
  }) : super(
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
