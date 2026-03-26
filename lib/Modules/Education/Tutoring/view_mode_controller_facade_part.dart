part of 'view_mode_controller.dart';

ViewModeController? maybeFindViewModeController() {
  final isRegistered = Get.isRegistered<ViewModeController>();
  if (!isRegistered) return null;
  return Get.find<ViewModeController>();
}

ViewModeController ensureViewModeController({bool permanent = false}) {
  final existing = maybeFindViewModeController();
  if (existing != null) return existing;
  return Get.put(ViewModeController(), permanent: permanent);
}
