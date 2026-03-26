part of 'view_mode_controller.dart';

abstract class _ViewModeControllerBase extends GetxController {
  final _state = _ViewModeControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(_ViewModeControllerRuntimePart(this as ViewModeController)
        .restoreViewMode());
  }
}
