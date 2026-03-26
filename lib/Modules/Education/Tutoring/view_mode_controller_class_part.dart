part of 'view_mode_controller.dart';

class ViewModeController extends _ViewModeControllerBase {
  static ViewModeController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ViewModeController(), permanent: permanent);
  }

  static ViewModeController? maybeFind() {
    final isRegistered = Get.isRegistered<ViewModeController>();
    if (!isRegistered) return null;
    return Get.find<ViewModeController>();
  }
}
