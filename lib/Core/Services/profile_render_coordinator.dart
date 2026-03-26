import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/render_list_patch.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'profile_render_coordinator_facade_part.dart';
part 'profile_render_coordinator_runtime_part.dart';
part 'profile_render_coordinator_patch_part.dart';

class ProfileRenderCoordinator extends GetxService {
  static ProfileRenderCoordinator? maybeFind() =>
      _maybeFindProfileRenderCoordinator();

  static ProfileRenderCoordinator ensure() => _ensureProfileRenderCoordinator();

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
