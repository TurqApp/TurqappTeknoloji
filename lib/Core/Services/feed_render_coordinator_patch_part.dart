part of 'feed_render_coordinator.dart';

extension FeedRenderCoordinatorPatchPart on FeedRenderCoordinator {
  RenderListPatch<Map<String, dynamic>> buildPatch({
    required List<Map<String, dynamic>> previous,
    required List<Map<String, dynamic>> next,
    String reason = '',
  }) {
    if (_sameRenderableSequence(previous, next)) {
      _trackPatch(
        previousCount: previous.length,
        nextCount: next.length,
        patch: const RenderListPatch<Map<String, dynamic>>(operations: []),
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

    final patch = RenderListPatch<Map<String, dynamic>>(
      operations: operations,
      reason: reason,
    );
    _trackPatch(
      previousCount: previous.length,
      nextCount: next.length,
      patch: patch,
    );
    return patch;
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

  bool _sameRenderableSequence(
    List<Map<String, dynamic>> previous,
    List<Map<String, dynamic>> next,
  ) {
    if (previous.length != next.length) return false;
    for (int i = 0; i < previous.length; i++) {
      if (_entryKey(previous[i]) != _entryKey(next[i])) {
        return false;
      }
      if (!_sameEntryPayload(previous[i], next[i])) {
        return false;
      }
    }
    return true;
  }

  bool _sameEntryPayload(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftRenderType = (left['renderType'] ?? 'post').toString();
    final rightRenderType = (right['renderType'] ?? 'post').toString();
    if (leftRenderType != rightRenderType) return false;
    if (leftRenderType == 'promo') {
      return left['promoType'] == right['promoType'] &&
          left['slotNumber'] == right['slotNumber'] &&
          left['recommendedBatch'] == right['recommendedBatch'];
    }
    final leftModel = left['model'] as PostsModel;
    final rightModel = right['model'] as PostsModel;
    return left['timestamp'] == right['timestamp'] &&
        left['agendaIndex'] == right['agendaIndex'] &&
        left['reshare'] == right['reshare'] &&
        left['reshareUserID'] == right['reshareUserID'] &&
        leftModel.docID == rightModel.docID &&
        leftModel.playbackUrl == rightModel.playbackUrl &&
        leftModel.thumbnail == rightModel.thumbnail &&
        leftModel.authorAvatarUrl == rightModel.authorAvatarUrl;
  }

  String _entryKey(Map<String, dynamic> entry) {
    final renderType = (entry['renderType'] ?? 'post').toString();
    if (renderType == 'promo') {
      return <String>[
        'promo',
        (entry['promoType'] ?? '').toString(),
        (entry['slotNumber'] ?? '').toString(),
      ].join('::');
    }
    final model = entry['model'] as PostsModel;
    final isReshare = entry['reshare'] == true;
    final reshareUserId = (entry['reshareUserID'] ?? '').toString();
    return <String>[
      model.docID,
      isReshare ? 'reshare' : 'normal',
      reshareUserId,
    ].join('::');
  }

  void _trackRenderEntries({
    required int filteredCount,
    required List<Map<String, dynamic>> renderEntries,
  }) {
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;
    final promoCount = renderEntries.where((entry) {
      return (entry['renderType'] ?? 'post') == 'promo';
    }).length;
    playbackKpi.track(
      PlaybackKpiEventType.renderDiff,
      <String, dynamic>{
        'surface': 'feed',
        'stage': 'render_entries',
        'filteredCount': filteredCount,
        'renderCount': renderEntries.length,
        'promoCount': promoCount,
      },
    );
  }

  void _trackPatch({
    required int previousCount,
    required int nextCount,
    required RenderListPatch<Map<String, dynamic>> patch,
  }) {
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;
    var insertCount = 0;
    var updateCount = 0;
    var removeCount = 0;
    var moveCount = 0;
    for (final operation in patch.operations) {
      switch (operation.type) {
        case RenderPatchOperationType.insert:
          insertCount += 1;
          break;
        case RenderPatchOperationType.update:
        case RenderPatchOperationType.replace:
          updateCount += 1;
          break;
        case RenderPatchOperationType.remove:
          removeCount += 1;
          break;
        case RenderPatchOperationType.move:
          moveCount += 1;
          break;
      }
    }
    playbackKpi.track(
      PlaybackKpiEventType.renderDiff,
      <String, dynamic>{
        'surface': 'feed',
        'stage': 'render_patch',
        'previousCount': previousCount,
        'nextCount': nextCount,
        'operations': patch.operations.length,
        'insertCount': insertCount,
        'updateCount': updateCount,
        'removeCount': removeCount,
        'moveCount': moveCount,
        'reason': patch.reason,
      },
    );
  }
}
