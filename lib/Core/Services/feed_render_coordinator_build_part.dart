part of 'feed_render_coordinator.dart';

extension FeedRenderCoordinatorBuildPart on FeedRenderCoordinator {
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

    // Main feed ordering stays anchored to real Posts documents. Bare reshare
    // events are kept as metadata until they are materialized as shared posts.

    final merged = displayByDoc.values.toList(growable: false)
      ..sort(
        (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );

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

  bool _shouldInsertPromoAfterPost(int postNumber) {
    return postNumber > 0 && postNumber % 3 == 0;
  }
}
