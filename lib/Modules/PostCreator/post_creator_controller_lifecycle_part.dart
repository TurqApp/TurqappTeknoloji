part of 'post_creator_controller.dart';

PostCreatorController _ensurePostCreatorController({
  bool permanent = false,
}) {
  final existing = _maybeFindPostCreatorController();
  if (existing != null) return existing;
  return Get.put(PostCreatorController(), permanent: permanent);
}

PostCreatorController? _maybeFindPostCreatorController() {
  final isRegistered = Get.isRegistered<PostCreatorController>();
  if (!isRegistered) return null;
  return Get.find<PostCreatorController>();
}

class _PostCreatorControllerLifecyclePart {
  final PostCreatorController controller;

  const _PostCreatorControllerLifecyclePart(this.controller);

  void handleOnInit() {
    WidgetsBinding.instance.addObserver(controller);
    controller._initializeServices();
    controller._startAutoSave();
  }

  void handleOnClose() {
    WidgetsBinding.instance.removeObserver(controller);
    controller._autoSaveTimer?.cancel();
    controller._queueRingTimer?.cancel();
    controller._saveCurrentDraft();
  }

  void handleDidChangeMetrics() {
    _PostCreatorControllerRouteX(controller)._handleDidChangeMetrics();
  }
}
