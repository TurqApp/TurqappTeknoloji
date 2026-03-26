part of 'solve_test_controller.dart';

abstract class _SolveTestControllerBase extends GetxController {
  _SolveTestControllerBase({
    required String testID,
    required Function showSucces,
  }) : _state = _SolveTestControllerState(
          testID: testID,
          showSucces: showSucces,
        );

  final _SolveTestControllerState _state;
}
