import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/render_list_patch.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'profile_render_coordinator_patch_part.dart';

class ProfileRenderCoordinator extends GetxService {
  static ProfileRenderCoordinator? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileRenderCoordinator>();
    if (!isRegistered) return null;
    return Get.find<ProfileRenderCoordinator>();
  }

  static ProfileRenderCoordinator ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileRenderCoordinator(), permanent: true);
  }

  List<Map<String, dynamic>> buildMergedEntries({
    required List<PostsModel> allPosts,
    required List<PostsModel> reshares,
    required int Function(String postId, int fallback) reshareSortTimestampFor,
  }) {
    final combined = <Map<String, dynamic>>[];

    for (final post in allPosts.where((post) =>
        !post.deletedPost && !post.arsiv && !post.shouldHideWhileUploading)) {
      combined.add(<String, dynamic>{
        'docID': post.docID,
        'post': post,
        'isReshare': false,
        'timestamp': post.timeStamp,
      });
    }

    for (final reshare in reshares.where((post) =>
        !post.deletedPost && !post.arsiv && !post.shouldHideWhileUploading)) {
      final reshareTimestamp = reshareSortTimestampFor(
        reshare.docID,
        reshare.timeStamp.toInt(),
      );
      combined.add(<String, dynamic>{
        'docID': reshare.docID,
        'post': reshare,
        'isReshare': true,
        'timestamp': reshareTimestamp,
      });
    }

    combined.sort(
      (a, b) => (b['timestamp'] as num).compareTo(a['timestamp'] as num),
    );
    return combined;
  }

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
