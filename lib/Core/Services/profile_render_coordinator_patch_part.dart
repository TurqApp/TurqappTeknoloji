part of 'profile_render_coordinator.dart';

class _ProfileRenderCoordinatorPatchPart {
  const _ProfileRenderCoordinatorPatchPart();

  bool _asProfileEntryBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  RenderListPatch<Map<String, dynamic>> buildPatch({
    required List<Map<String, dynamic>> previous,
    required List<Map<String, dynamic>> next,
  }) {
    if (_sameRenderableSequence(previous, next)) {
      _trackPatch(
        previousCount: previous.length,
        nextCount: next.length,
        operations: 0,
      );
      return const RenderListPatch<Map<String, dynamic>>(operations: []);
    }

    final operations = <RenderPatchOperation<Map<String, dynamic>>>[];
    final sharedLength =
        previous.length < next.length ? previous.length : next.length;

    for (int i = 0; i < sharedLength; i++) {
      if (_entryKey(previous[i]) != _entryKey(next[i]) ||
          !_sameEntryPayload(previous[i], next[i])) {
        operations.add(
          RenderPatchOperation<Map<String, dynamic>>(
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
          RenderPatchOperation<Map<String, dynamic>>(
            type: RenderPatchOperationType.insert,
            index: i,
            item: next[i],
          ),
        );
      }
    } else if (previous.length > next.length) {
      for (int i = previous.length - 1; i >= next.length; i--) {
        operations.add(
          RenderPatchOperation<Map<String, dynamic>>(
            type: RenderPatchOperationType.remove,
            index: i,
          ),
        );
      }
    }

    _trackPatch(
      previousCount: previous.length,
      nextCount: next.length,
      operations: operations.length,
    );
    return RenderListPatch<Map<String, dynamic>>(
      operations: operations,
      reason: 'profile_merged_posts',
    );
  }

  void applyPatch(
    RxList<Map<String, dynamic>> target,
    RenderListPatch<Map<String, dynamic>> patch,
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
              operation.index >= target.length) {
            continue;
          }
          final item = target.removeAt(fromIndex);
          target.insert(operation.index, item);
          break;
      }
    }
  }

  String _entryKey(Map<String, dynamic> entry) {
    final post = entry['post'] as PostsModel;
    final isReshare = _asProfileEntryBool(entry['isReshare']);
    return '${post.docID}|${isReshare ? 'reshare' : 'post'}';
  }

  bool _sameRenderableSequence(
    List<Map<String, dynamic>> previous,
    List<Map<String, dynamic>> next,
  ) {
    if (previous.length != next.length) return false;
    for (int i = 0; i < previous.length; i++) {
      if (_entryKey(previous[i]) != _entryKey(next[i])) return false;
      if (!_sameEntryPayload(previous[i], next[i])) return false;
    }
    return true;
  }

  bool _sameEntryPayload(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftPost = left['post'] as PostsModel;
    final rightPost = right['post'] as PostsModel;
    return (_asProfileEntryBool(left['isReshare']) ==
            _asProfileEntryBool(right['isReshare'])) &&
        (left['timestamp'] == right['timestamp']) &&
        leftPost.playbackUrl == rightPost.playbackUrl &&
        leftPost.thumbnail == rightPost.thumbnail &&
        leftPost.authorAvatarUrl == rightPost.authorAvatarUrl &&
        leftPost.authorDisplayName == rightPost.authorDisplayName &&
        leftPost.authorNickname == rightPost.authorNickname &&
        leftPost.rozet == rightPost.rozet &&
        leftPost.timeStamp == rightPost.timeStamp;
  }

  void _trackPatch({
    required int previousCount,
    required int nextCount,
    required int operations,
  }) {
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;
    playbackKpi.track(
      PlaybackKpiEventType.renderDiff,
      <String, dynamic>{
        'surface': 'profile',
        'stage': 'render_patch',
        'previousCount': previousCount,
        'nextCount': nextCount,
        'operations': operations,
      },
    );
  }
}
