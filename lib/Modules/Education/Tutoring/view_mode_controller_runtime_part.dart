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
      final preferences = ensureLocalPreferenceRepository();
      controller.isGridView.value =
          await preferences.getBool(viewModeKeyFor(uid)) ?? true;
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
      final preferences = ensureLocalPreferenceRepository();
      await preferences.setBool(
        viewModeKeyFor(uid),
        controller.isGridView.value,
      );
    } catch (_) {}
  }

  void toggleView() {
    controller.isGridView.value = !controller.isGridView.value;
    unawaited(persistViewMode());
  }
}
