part of 'tutoring_controller.dart';

TutoringController _ensureTutoringController({bool permanent = false}) {
  final existing = _maybeFindTutoringController();
  if (existing != null) return existing;
  return Get.put(TutoringController(), permanent: permanent);
}

TutoringController? _maybeFindTutoringController() {
  final isRegistered = Get.isRegistered<TutoringController>();
  if (!isRegistered) return null;
  return Get.find<TutoringController>();
}

bool _hasActiveTutoringSearch(TutoringController controller) =>
    controller.searchQuery.value.trim().length >= 2;

void _handleTutoringControllerInit(TutoringController controller) {
  controller.scrollController.addListener(controller._onScroll);
  unawaited(_bootstrapTutoringDataImpl(controller));
}

Future<void> _bootstrapTutoringDataImpl(TutoringController controller) async {
  final savedController = SavedTutoringsController.ensure(permanent: true);
  await savedController.loadSavedTutorings();
  final userId = CurrentUserService.instance.effectiveUserId;
  controller._homeSnapshotSub?.cancel();
  controller._homeSnapshotSub = controller._tutoringSnapshotRepository
      .openHome(
        userId: userId,
        limit: TutoringController._pageSize,
      )
      .listen(controller._applyHomeSnapshotResource);
}

void _handleTutoringControllerClose(TutoringController controller) {
  controller._homeSnapshotSub?.cancel();
  controller._searchDebounce?.cancel();
  controller.focusNode.dispose();
  controller.searchPreviewController.dispose();
  controller.scrollController.dispose();
}
