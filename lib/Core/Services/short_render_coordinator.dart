import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/render_list_patch.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'short_render_coordinator_patch_part.dart';

class ShortRenderUpdate {
  const ShortRenderUpdate({
    required this.patch,
    required this.remappedIndex,
  });

  final RenderListPatch<PostsModel> patch;
  final int remappedIndex;
}

class ShortRenderCoordinator extends GetxService {
  static ShortRenderCoordinator? maybeFind() {
    final isRegistered = Get.isRegistered<ShortRenderCoordinator>();
    if (!isRegistered) return null;
    return Get.find<ShortRenderCoordinator>();
  }

  static ShortRenderCoordinator ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ShortRenderCoordinator(), permanent: true);
  }

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
