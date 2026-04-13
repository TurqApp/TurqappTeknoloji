part of 'feed_render_coordinator.dart';

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
    var promoOrdinal = 0;
    var recommendedOrdinal = 0;
    var postCursor = 0;
    var renderBlockIndex = 0;
    while (postCursor < filteredEntries.length) {
      final blockStartPostCursor = postCursor;
      final blockPostCount = (filteredEntries.length - blockStartPostCursor) <
              FeedRenderBlockPlan.postSlotsPerBlock
          ? (filteredEntries.length - blockStartPostCursor)
          : FeedRenderBlockPlan.postSlotsPerBlock;
      for (int slotIndex = 0;
          slotIndex < FeedRenderBlockPlan.renderSlotPlan.length;
          slotIndex++) {
        if (normalizedMaxRenderEntries != null &&
            renderEntries.length >= normalizedMaxRenderEntries) {
          _trackRenderEntries(
            filteredCount: filteredEntries.length,
            renderEntries: renderEntries,
          );
          return renderEntries;
        }

        final slotType = FeedRenderBlockPlan.renderSlotPlan[slotIndex];
        final renderSlotNumber = slotIndex + 1;
        final renderGroupNumber =
            (slotIndex ~/ FeedRenderBlockPlan.renderSlotsPerGroup) + 1;

        if (slotType == FeedRenderSlotType.post) {
          final postsConsumedInBlock = postCursor - blockStartPostCursor;
          if (postsConsumedInBlock >= blockPostCount) {
            break;
          }
          final postEntry = Map<String, dynamic>.from(filteredEntries[postCursor])
            ..putIfAbsent('renderType', () => 'post')
            ..putIfAbsent('renderBlockIndex', () => renderBlockIndex)
            ..putIfAbsent('renderSlotNumber', () => renderSlotNumber)
            ..putIfAbsent('renderGroupNumber', () => renderGroupNumber);
          renderEntries.add(postEntry);
          postCursor++;
          continue;
        }

        final requiredPostCountForPromo =
            renderGroupNumber * FeedRenderBlockPlan.postsPerGroup;
        if (blockPostCount < requiredPostCountForPromo) {
          break;
        }

        final promoType = slotType == FeedRenderSlotType.recommended
            ? 'recommended'
            : 'ad';
        renderEntries.add(<String, dynamic>{
          'renderType': 'promo',
          'promoType': promoType,
          'slotNumber': promoOrdinal + 1,
          'renderBlockIndex': renderBlockIndex,
          'renderSlotNumber': renderSlotNumber,
          'renderGroupNumber': renderGroupNumber,
          'recommendedBatch':
              slotType == FeedRenderSlotType.recommended
                  ? recommendedOrdinal++
                  : -1,
        });
        promoOrdinal++;
      }
      renderBlockIndex++;
    }
    _trackRenderEntries(
      filteredCount: filteredEntries.length,
      renderEntries: renderEntries,
    );
    return renderEntries;
  }
}
