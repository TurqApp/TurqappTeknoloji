part of 'view_mode_controller.dart';

ViewModeController? maybeFindViewModeController() =>
    Get.isRegistered<ViewModeController>()
        ? Get.find<ViewModeController>()
        : null;

ViewModeController ensureViewModeController({bool permanent = false}) =>
    maybeFindViewModeController() ??
    Get.put(ViewModeController(), permanent: permanent);
