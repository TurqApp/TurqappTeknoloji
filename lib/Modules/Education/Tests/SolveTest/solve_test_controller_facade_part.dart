part of 'solve_test_controller.dart';

SolveTestController ensureSolveTestController({
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

SolveTestController? maybeFindSolveTestController({String? tag}) =>
    _maybeFindSolveTestController(tag: tag);
