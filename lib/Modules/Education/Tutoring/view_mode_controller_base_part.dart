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

class ViewModeController extends _ViewModeControllerBase {}

ViewModeController? maybeFindViewModeController() =>
    Get.isRegistered<ViewModeController>()
        ? Get.find<ViewModeController>()
        : null;

ViewModeController ensureViewModeController({bool permanent = false}) =>
    maybeFindViewModeController() ??
    Get.put(ViewModeController(), permanent: permanent);
