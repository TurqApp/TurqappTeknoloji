part of 'view_mode_controller.dart';

const String _viewModePrefKeyPrefix = 'pasaj_tutoring_view_mode';

class _ViewModeControllerState {
  final RxBool isGridView = true.obs;
  final RxBool isReady = false.obs;
}

extension ViewModeControllerFieldsPart on ViewModeController {
  RxBool get isGridView => _state.isGridView;
  RxBool get isReady => _state.isReady;

  void toggleView() => _ViewModeControllerRuntimePart(this).toggleView();
}
