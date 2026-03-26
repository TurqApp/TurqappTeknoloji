part of 'view_mode_controller.dart';

class _ViewModeControllerRuntimePart {
  const _ViewModeControllerRuntimePart(this.controller);

  final ViewModeController controller;

  String viewModeKeyFor(String uid) => '${_viewModePrefKeyPrefix}_$uid';

  Future<void> restoreViewMode() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      controller.isGridView.value = true;
      controller.isReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      controller.isGridView.value = prefs.getBool(viewModeKeyFor(uid)) ?? true;
    } catch (_) {
      controller.isGridView.value = true;
    } finally {
      controller.isReady.value = true;
    }
  }

  Future<void> persistViewMode() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(viewModeKeyFor(uid), controller.isGridView.value);
    } catch (_) {}
  }

  void toggleView() {
    controller.isGridView.value = !controller.isGridView.value;
    unawaited(persistViewMode());
  }
}
