part of 'profile_render_coordinator.dart';

ProfileRenderCoordinator? maybeFindProfileRenderCoordinator() =>
    _maybeFindProfileRenderCoordinator();

ProfileRenderCoordinator ensureProfileRenderCoordinator() =>
    _ensureProfileRenderCoordinator();

ProfileRenderCoordinator? _maybeFindProfileRenderCoordinator() {
  final isRegistered = Get.isRegistered<ProfileRenderCoordinator>();
  if (!isRegistered) return null;
  return Get.find<ProfileRenderCoordinator>();
}

ProfileRenderCoordinator _ensureProfileRenderCoordinator() {
  final existing = _maybeFindProfileRenderCoordinator();
  if (existing != null) return existing;
  return Get.put(ProfileRenderCoordinator(), permanent: true);
}

extension ProfileRenderCoordinatorFacadePart on ProfileRenderCoordinator {
  List<Map<String, dynamic>> buildMergedEntries({
    required List<PostsModel> allPosts,
    required List<PostsModel> reshares,
    required int Function(String postId, int fallback) reshareSortTimestampFor,
  }) =>
      _buildProfileMergedEntries(
        allPosts: allPosts,
        reshares: reshares,
        reshareSortTimestampFor: reshareSortTimestampFor,
      );

  RenderListPatch<Map<String, dynamic>> buildPatch({
    required List<Map<String, dynamic>> previous,
    required List<Map<String, dynamic>> next,
  }) =>
      const _ProfileRenderCoordinatorPatchPart().buildPatch(
        previous: previous,
        next: next,
      );

  void applyPatch(
    RxList<Map<String, dynamic>> target,
    RenderListPatch<Map<String, dynamic>> patch,
  ) =>
      const _ProfileRenderCoordinatorPatchPart().applyPatch(target, patch);
}
