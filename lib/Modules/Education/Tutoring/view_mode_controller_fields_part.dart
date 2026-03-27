part of 'view_mode_controller.dart';

class _ViewModeControllerState {
  final RxBool isGridView = true.obs, isReady = false.obs;
}

extension ViewModeControllerFieldsPart on ViewModeController {
  RxBool get isGridView => _state.isGridView;
  RxBool get isReady => _state.isReady;
  void toggleView() => _ViewModeControllerRuntimePart(this).toggleView();
}
