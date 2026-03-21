import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/render_list_patch.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/posts_model.dart';

class FeedRenderCoordinator extends GetxService {
  static const int _mediaReadyWindow = 10;

  static FeedRenderCoordinator _ensureService() {
    if (Get.isRegistered<FeedRenderCoordinator>()) {
      return Get.find<FeedRenderCoordinator>();
    }
    return Get.put(FeedRenderCoordinator(), permanent: true);
  }

  static FeedRenderCoordinator ensure() {
    return _ensureService();
  }

  List<Map<String, dynamic>> buildMergedEntries({
    required List<PostsModel> agendaList,
    required List<Map<String, dynamic>> feedReshareEntries,
  }) {
    if (agendaList.isEmpty && feedReshareEntries.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final agendaIndexByDoc = <String, int>{
      for (int i = 0; i < agendaList.length; i++) agendaList[i].docID: i,
    };

    final displayByDoc = <String, Map<String, dynamic>>{};

    for (int i = 0; i < agendaList.length; i++) {
      final post = agendaList[i];
      displayByDoc[post.docID] = <String, dynamic>{
        'type': 'normal',
        'model': post,
        'reshare': false,
        'reshareUserID': null,
        'timestamp': post.timeStamp,
        'agendaIndex': i,
      };
    }

    for (final reshareEntry in feedReshareEntries) {
      final post = reshareEntry['post'] as PostsModel;
      final idx = agendaIndexByDoc[post.docID] ?? -1;
      final modelRef = idx >= 0 ? agendaList[idx] : post;
      final reshareTimestamp = (reshareEntry['reshareTimestamp'] ?? 0) as int;
      final reshareUserID = reshareEntry['reshareUserID'] as String?;

      final existing = displayByDoc[post.docID];
      final existingTs = (existing?['timestamp'] ?? 0) as int;
      if (existing == null || reshareTimestamp >= existingTs) {
        displayByDoc[post.docID] = <String, dynamic>{
          'type': 'reshare',
          'model': modelRef,
          'reshare': true,
          'reshareUserID': reshareUserID,
          'timestamp': reshareTimestamp,
          'agendaIndex': idx,
        };
      }
    }

    final merged = displayByDoc.values.toList(growable: false)
      ..sort(
        (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );

    return _rerankMediaReadyEntries(merged);
  }

  List<Map<String, dynamic>> filterEntries({
    required List<Map<String, dynamic>> mergedEntries,
    required bool isFollowingMode,
    required bool isCityMode,
    required Set<String> followingIds,
    required String city,
  }) {
    if (mergedEntries.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    List<Map<String, dynamic>> filtered = mergedEntries.toList(growable: false);

    if (isFollowingMode && followingIds.isNotEmpty) {
      filtered = filtered.where((item) {
        final model = item['model'] as PostsModel;
        return followingIds.contains(model.userID);
      }).toList(growable: false);
    } else if (isCityMode) {
      final normalizedCity = normalizeLocationText(city);
      filtered = filtered.where((item) {
        final model = item['model'] as PostsModel;
        return normalizeLocationText(model.locationCity) == normalizedCity;
      }).toList(growable: false);
    }

    return filtered;
  }

  List<Map<String, dynamic>> buildRenderEntries({
    required List<Map<String, dynamic>> filteredEntries,
  }) {
    if (filteredEntries.isEmpty) return const <Map<String, dynamic>>[];

    final renderEntries = <Map<String, dynamic>>[];
    for (int i = 0; i < filteredEntries.length; i++) {
      final postEntry = Map<String, dynamic>.from(filteredEntries[i])
        ..putIfAbsent('renderType', () => 'post');
      renderEntries.add(postEntry);

      final postNumber = i + 1;
      if (!_shouldInsertPromoAfterPost(postNumber)) continue;
      final slotNumber = postNumber ~/ 3;
      final isAd = slotNumber.isOdd;
      renderEntries.add(<String, dynamic>{
        'renderType': 'promo',
        'promoType': isAd ? 'ad' : 'recommended',
        'slotNumber': slotNumber,
        'recommendedBatch': slotNumber ~/ 2,
      });
    }
    _trackRenderEntries(
      filteredCount: filteredEntries.length,
      renderEntries: renderEntries,
    );
    return renderEntries;
  }

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

  List<Map<String, dynamic>> _rerankMediaReadyEntries(
    List<Map<String, dynamic>> entries,
  ) {
    if (entries.length < 2) return entries;

    final windowEnd =
        entries.length < _mediaReadyWindow ? entries.length : _mediaReadyWindow;
    final head = entries.take(windowEnd).toList(growable: false);
    final tail = entries.skip(windowEnd).toList(growable: false);

    final readyVideo = <Map<String, dynamic>>[];
    final readyVisual = <Map<String, dynamic>>[];
    final rest = <Map<String, dynamic>>[];

    for (final entry in head) {
      final model = entry['model'] as PostsModel;
      if (model.hasPlayableVideo) {
        readyVideo.add(entry);
      } else if (model.img.isNotEmpty || model.thumbnail.trim().isNotEmpty) {
        readyVisual.add(entry);
      } else {
        rest.add(entry);
      }
    }

    return <Map<String, dynamic>>[
      ...readyVideo,
      ...readyVisual,
      ...rest,
      ...tail,
    ];
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

  bool _shouldInsertPromoAfterPost(int postNumber) {
    return postNumber > 0 && postNumber % 3 == 0;
  }

  void _trackRenderEntries({
    required int filteredCount,
    required List<Map<String, dynamic>> renderEntries,
  }) {
    final playbackKpi = PlaybackKpiService.maybeFind();
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
    final playbackKpi = PlaybackKpiService.maybeFind();
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
