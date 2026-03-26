part of 'short_render_coordinator.dart';

ShortRenderCoordinator? maybeFindShortRenderCoordinator() {
  final isRegistered = Get.isRegistered<ShortRenderCoordinator>();
  if (!isRegistered) return null;
  return Get.find<ShortRenderCoordinator>();
}

ShortRenderCoordinator ensureShortRenderCoordinator() {
  final existing = maybeFindShortRenderCoordinator();
  if (existing != null) return existing;
  return Get.put(ShortRenderCoordinator(), permanent: true);
}

extension ShortRenderCoordinatorFacadePart on ShortRenderCoordinator {
  ShortRenderUpdate buildUpdate({
    required List<PostsModel> previous,
    required List<PostsModel> next,
    required int currentIndex,
  }) =>
      _ShortRenderCoordinatorPatchX(this).buildUpdate(
        previous: previous,
        next: next,
        currentIndex: currentIndex,
      );

  void trackUpdateMetrics({
    required List<PostsModel> previous,
    required int currentIndex,
    required ShortRenderUpdate update,
    required List<PostsModel> next,
  }) =>
      _ShortRenderCoordinatorPatchX(this).trackUpdateMetrics(
        previous: previous,
        currentIndex: currentIndex,
        update: update,
        next: next,
      );

  void applyPatch(
    List<PostsModel> target,
    RenderListPatch<PostsModel> patch,
  ) =>
      _ShortRenderCoordinatorPatchX(this).applyPatch(target, patch);
}
