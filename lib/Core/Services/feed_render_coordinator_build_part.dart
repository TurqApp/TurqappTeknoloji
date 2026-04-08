part of 'feed_render_coordinator.dart';

const List<String> _feedPromoCycle = <String>[
  'ad',
  'recommended',
  'ad',
  'ad',
  'recommended',
];

extension FeedRenderCoordinatorBuildPart on FeedRenderCoordinator {
  List<Map<String, dynamic>> buildMergedEntries({
    required List<PostsModel> agendaList,
    required List<Map<String, dynamic>> feedReshareEntries,
    required Map<String, int> myReshares,
    required String currentUserId,
  }) {
    if (agendaList.isEmpty && feedReshareEntries.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final displayByDoc = <String, Map<String, dynamic>>{};

    for (int i = 0; i < agendaList.length; i++) {
      final post = agendaList[i];
      final selfReshareTimestamp = myReshares[post.docID] ?? 0;
      final isSelfReshare = selfReshareTimestamp > 0;
      displayByDoc[post.docID] = <String, dynamic>{
        'type': isSelfReshare ? 'reshare' : 'normal',
        'model': post,
        'reshare': isSelfReshare,
        'reshareUserID':
            isSelfReshare && currentUserId.isNotEmpty ? currentUserId : null,
        'timestamp': isSelfReshare ? selfReshareTimestamp : post.timeStamp,
        'agendaIndex': i,
      };
    }

    // Main feed ordering stays anchored to real Posts documents. Bare reshare
    // events are kept as metadata until they are materialized as shared posts.

    final merged = <Map<String, dynamic>>[];
    for (final post in agendaList) {
      final entry = displayByDoc[post.docID];
      if (entry != null) {
        merged.add(entry);
      }
    }

    return merged;
  }

  List<Map<String, dynamic>> filterEntries({
    required List<Map<String, dynamic>> mergedEntries,
    required bool isFollowingMode,
    required bool isCityMode,
    required Set<String> followingIds,
    required String currentUserId,
    required String city,
  }) {
    if (mergedEntries.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    List<Map<String, dynamic>> filtered = mergedEntries.toList(growable: false);

    if (isFollowingMode && followingIds.isNotEmpty) {
      filtered = filtered.where((item) {
        final model = item['model'] as PostsModel;
        return model.userID == currentUserId ||
            followingIds.contains(model.userID);
      }).toList(growable: false);
    } else if (isCityMode) {
      final normalizedCity = normalizeLocationText(city);
      filtered = filtered.where((item) {
        final model = item['model'] as PostsModel;
        if (model.userID == currentUserId) return true;
        return normalizeLocationText(model.locationCity) == normalizedCity;
      }).toList(growable: false);
    }

    return filtered;
  }

  List<Map<String, dynamic>> buildRenderEntries({
    required List<Map<String, dynamic>> filteredEntries,
    int? maxRenderEntries,
  }) {
    if (filteredEntries.isEmpty) return const <Map<String, dynamic>>[];

    final normalizedMaxRenderEntries =
        maxRenderEntries != null && maxRenderEntries > 0
            ? maxRenderEntries
            : null;
    final renderEntries = <Map<String, dynamic>>[];
    for (int i = 0; i < filteredEntries.length; i++) {
      if (normalizedMaxRenderEntries != null &&
          renderEntries.length >= normalizedMaxRenderEntries) {
        break;
      }
      final postEntry = Map<String, dynamic>.from(filteredEntries[i])
        ..putIfAbsent('renderType', () => 'post');
      renderEntries.add(postEntry);

      if (normalizedMaxRenderEntries != null &&
          renderEntries.length >= normalizedMaxRenderEntries) {
        break;
      }
      final postNumber = i + 1;
      if (!_shouldInsertPromoAfterPost(postNumber)) continue;
      final promoOrdinal = (postNumber ~/ 3) - 1;
      final slotNumber = promoOrdinal + 1;
      final promoType = _feedPromoCycle[promoOrdinal % _feedPromoCycle.length];
      renderEntries.add(<String, dynamic>{
        'renderType': 'promo',
        'promoType': promoType,
        'slotNumber': slotNumber,
        'recommendedBatch': _recommendedBatchForPromoOrdinal(promoOrdinal),
      });
    }
    _trackRenderEntries(
      filteredCount: filteredEntries.length,
      renderEntries: renderEntries,
    );
    return renderEntries;
  }

  bool _shouldInsertPromoAfterPost(int postNumber) {
    return postNumber > 0 && postNumber % 3 == 0;
  }

  int _recommendedBatchForPromoOrdinal(int promoOrdinal) {
    final fullCycles = promoOrdinal ~/ _feedPromoCycle.length;
    final offset = promoOrdinal % _feedPromoCycle.length;
    if (offset == 1) {
      return fullCycles * 2;
    }
    if (offset == 4) {
      return (fullCycles * 2) + 1;
    }
    return fullCycles * 2;
  }
}
