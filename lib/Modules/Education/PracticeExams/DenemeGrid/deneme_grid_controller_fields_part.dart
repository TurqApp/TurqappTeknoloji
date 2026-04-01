part of 'deneme_grid_controller.dart';

class _DenemeGridControllerState {
  final toplamBasvuru = 0.obs;
  final currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  final examTime = 0.obs;
  final int fifteenMinutes = 15 * 60 * 1000;
  String initializedDocId = '';
}

extension DenemeGridControllerFieldsPart on DenemeGridController {
  RxInt get toplamBasvuru => _state.toplamBasvuru;
  RxInt get currentTime => _state.currentTime;
  RxInt get examTime => _state.examTime;
  int get fifteenMinutes => _state.fifteenMinutes;
  String get _initializedDocId => _state.initializedDocId;
  set _initializedDocId(String value) => _state.initializedDocId = value;
}
