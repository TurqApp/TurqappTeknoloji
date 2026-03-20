import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/render_list_patch.dart';
import 'package:turqappv2/Models/posts_model.dart';

class ShortRenderUpdate {
  const ShortRenderUpdate({
    required this.patch,
    required this.remappedIndex,
  });

  final RenderListPatch<PostsModel> patch;
  final int remappedIndex;
}

class ShortRenderCoordinator extends GetxService {
  static ShortRenderCoordinator ensure() {
    if (Get.isRegistered<ShortRenderCoordinator>()) {
      return Get.find<ShortRenderCoordinator>();
    }
    return Get.put(ShortRenderCoordinator(), permanent: true);
  }

  ShortRenderUpdate buildUpdate({
    required List<PostsModel> previous,
    required List<PostsModel> next,
    required int currentIndex,
  }) {
    final patch = _buildPatch(previous: previous, next: next);
    final remappedIndex = _remapIndex(
      previous: previous,
      next: next,
      currentIndex: currentIndex,
    );
    return ShortRenderUpdate(
      patch: patch,
      remappedIndex: remappedIndex,
    );
  }

  void applyPatch(
    List<PostsModel> target,
    RenderListPatch<PostsModel> patch,
  ) {
    if (patch.isEmpty) return;
    for (final operation in patch.operations) {
      switch (operation.type) {
        case RenderPatchOperationType.insert:
          final item = operation.item;
          if (item == null) continue;
          if (operation.index >= 0 && operation.index <= target.length) {
            target.insert(operation.index, item);
          } else {
            target.add(item);
          }
          break;
        case RenderPatchOperationType.update:
        case RenderPatchOperationType.replace:
          final item = operation.item;
          if (item == null) continue;
          if (operation.index >= 0 && operation.index < target.length) {
            target[operation.index] = item;
          } else if (operation.index == target.length) {
            target.add(item);
          }
          break;
        case RenderPatchOperationType.remove:
          if (operation.index >= 0 && operation.index < target.length) {
            target.removeAt(operation.index);
          }
          break;
        case RenderPatchOperationType.move:
          final fromIndex = operation.fromIndex;
          if (fromIndex == null ||
              fromIndex < 0 ||
              fromIndex >= target.length ||
              operation.index < 0 ||
              operation.index > target.length) {
            continue;
          }
          final item = target.removeAt(fromIndex);
          target.insert(operation.index, item);
          break;
      }
    }
  }

  RenderListPatch<PostsModel> _buildPatch({
    required List<PostsModel> previous,
    required List<PostsModel> next,
  }) {
    if (_sameRenderableList(previous, next)) {
      return const RenderListPatch<PostsModel>(operations: []);
    }

    final operations = <RenderPatchOperation<PostsModel>>[];
    final sharedLength = previous.length < next.length ? previous.length : next.length;
    for (int i = 0; i < sharedLength; i++) {
      if (previous[i].docID != next[i].docID || !_samePayload(previous[i], next[i])) {
        operations.add(
          RenderPatchOperation<PostsModel>(
            type: RenderPatchOperationType.update,
            index: i,
            item: next[i],
          ),
        );
      }
    }

    if (next.length > previous.length) {
      for (int i = previous.length; i < next.length; i++) {
        operations.add(
          RenderPatchOperation<PostsModel>(
            type: RenderPatchOperationType.insert,
            index: i,
            item: next[i],
          ),
        );
      }
    } else if (previous.length > next.length) {
      for (int i = previous.length - 1; i >= next.length; i--) {
        operations.add(
          RenderPatchOperation<PostsModel>(
            type: RenderPatchOperationType.remove,
            index: i,
          ),
        );
      }
    }

    return RenderListPatch<PostsModel>(
      operations: operations,
      reason: 'short_render_update',
    );
  }

  int _remapIndex({
    required List<PostsModel> previous,
    required List<PostsModel> next,
    required int currentIndex,
  }) {
    if (next.isEmpty) return 0;
    if (previous.isEmpty) {
      return currentIndex.clamp(0, next.length - 1);
    }
    final safeCurrent = currentIndex.clamp(0, previous.length - 1);
    final currentDocId = previous[safeCurrent].docID;
    final nextIndex = next.indexWhere((item) => item.docID == currentDocId);
    if (nextIndex >= 0) return nextIndex;
    return safeCurrent.clamp(0, next.length - 1);
  }

  bool _sameRenderableList(
    List<PostsModel> previous,
    List<PostsModel> next,
  ) {
    if (previous.length != next.length) return false;
    for (int i = 0; i < previous.length; i++) {
      if (previous[i].docID != next[i].docID) return false;
      if (!_samePayload(previous[i], next[i])) return false;
    }
    return true;
  }

  bool _samePayload(PostsModel left, PostsModel right) {
    return left.playbackUrl == right.playbackUrl &&
        left.thumbnail == right.thumbnail &&
        left.authorAvatarUrl == right.authorAvatarUrl &&
        left.authorDisplayName == right.authorDisplayName &&
        left.authorNickname == right.authorNickname &&
        left.rozet == right.rozet &&
        left.timeStamp == right.timeStamp;
  }
}
