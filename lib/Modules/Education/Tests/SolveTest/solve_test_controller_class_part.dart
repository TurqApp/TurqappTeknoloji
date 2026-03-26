part of 'solve_test_controller.dart';

class SolveTestController extends GetxController {
  static SolveTestController ensure({
    required String testID,
    required Function showSucces,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureSolveTestController(
        testID: testID,
        showSucces: showSucces,
        tag: tag,
        permanent: permanent,
      );

  static SolveTestController? maybeFind({String? tag}) =>
      _maybeFindSolveTestController(tag: tag);

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
