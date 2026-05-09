part of 'tag_posts_controller.dart';

extension TagPostsControllerRuntimePart on TagPostsController {
  Future<void> getPosts() async {
    const progressiveLimits = <int>[5, 10, 15, 20, 50];
    final generation = _fetchGeneration + 1;
    _fetchGeneration = generation;
    final merged = <String, PostsModel>{};

    for (final limit in progressiveLimits) {
      final startedAt = DateTime.now();
      final fetchedPosts = await _repo.fetchByTag(
        tag,
        limit: limit,
        fastFirstPaint: limit == progressiveLimits.first,
      );
      if (_fetchGeneration != generation) return;
      for (final post in fetchedPosts) {
        final docId = post.docID.trim();
        if (docId.isEmpty) continue;
        merged[docId] = post;
      }
      final nextPosts = merged.values.toList(growable: false);
      list.assignAll(nextPosts);
      _pruneVisibilityState();
      if (nextPosts.isNotEmpty && currentVisibleIndex.value < 0) {
        centeredIndex.value = 0;
        currentVisibleIndex.value = 0;
        lastCenteredIndex = 0;
        capturePendingCenteredEntry(preferredIndex: 0);
      }
      debugPrint(
        '[TagPostsFetch] tag=$tag limit=$limit '
        'fetched=${fetchedPosts.length} visible=${nextPosts.length} '
        'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
      );
      if (fetchedPosts.isEmpty) break;
      if (limit != progressiveLimits.first && fetchedPosts.length < limit) {
        break;
      }
    }
  }

  void _handleTagPostsInit() {
    getPosts();
  }

  void _handleTagPostsClose() {
    if (_activeTagPostsControllerTag == controllerTag) {
      _activeTagPostsControllerTag = null;
    }
    _visibleFractions.clear();
    _visibleUpdatedAt.clear();
  }

  String capitalizeAfterHash(String tag) {
    if (tag.startsWith('#') && tag.length > 1) {
      return '#${tag[1].toUpperCase()}${tag.substring(2)}';
    } else if (tag.isNotEmpty) {
      return tag[0].toUpperCase() + tag.substring(1);
    }
    return tag;
  }

  String agendaInstanceTag(String docId) => 'tag_post_$docId';

  GlobalKey getAgendaKey({required String docId}) {
    return _agendaKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(agendaInstanceTag(docId)),
    );
  }

  void disposeAgendaContentController(String docId) {
    final tag = agendaInstanceTag(docId);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= list.length) return;
    final previousFraction = _visibleFractions[modelIndex];
    if (FeedPlaybackSelectionPolicy.shouldIgnoreVisibilityUpdate(
      previousFraction: previousFraction,
      visibleFraction: visibleFraction,
    )) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      _visibleUpdatedAt[modelIndex] = DateTime.now();
    }
    _pruneVisibilityState(anchorIndex: modelIndex);
    _evaluateVisiblePlaybackTarget();
  }

  void _evaluateVisiblePlaybackTarget() {
    if (list.isEmpty || _visibleFractions.isEmpty) return;
    final current = centeredIndex.value;
    final decision = FeedPlaybackSelectionPolicy.resolvePlaybackDecision(
      visibleFractions: _visibleFractions,
      visibleUpdatedAt: _visibleUpdatedAt,
      currentIndex: current,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: list.length,
      canAutoplayIndex: (index) =>
          index >= 0 && index < list.length && list[index].hasPlayableVideo,
      isPlaybackTargetCurrent: (_) => false,
      playbackKeyForIndex: (index) => 'tag_post_${list[index].docID}',
      lastCommandAt: null,
      lastCommandDocId: null,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
      supportsSwitchRetention: false,
      preferDominantVisibleIndexWhenNonPlayable: true,
    );
    if (!decision.hasTarget) return;
    final target = decision.targetIndex;
    if (target < 0 || target >= list.length) return;
    if (current == target) return;
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length &&
        lastCenteredIndex != target) {
      disposeAgendaContentController(list[lastCenteredIndex!].docID);
    }
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
    capturePendingCenteredEntry(preferredIndex: target);
    debugPrint(
      '[TagPostsCenter] source=visibility action=${decision.action} '
      'previous=$current next=$target doc=${list[target].docID} '
      'visible=${_visibleFractions.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').join(',')}',
    );
  }

  void _pruneVisibilityState({int? anchorIndex}) {
    final anchor = anchorIndex ?? centeredIndex.value;
    final keysToRemove = <int>[];
    _visibleFractions.forEach((index, fraction) {
      if (index < 0 || index >= list.length) {
        keysToRemove.add(index);
        return;
      }
      if (anchor >= 0 && (index - anchor).abs() > 8) {
        keysToRemove.add(index);
      }
    });
    for (final index in keysToRemove) {
      _visibleFractions.remove(index);
      _visibleUpdatedAt.remove(index);
    }
  }

  void updateVisibleIndexByPosition(ScrollController controller) {
    if (!controller.hasClients || list.isEmpty) return;
    final position = controller.position;
    if (position.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
      return;
    }
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((position.pixels + position.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, list.length - 1);
    if (lastCenteredIndex != null &&
        lastCenteredIndex != nextIndex &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      disposeAgendaContentController(list[lastCenteredIndex!].docID);
    }
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
  }

  void updateVisibleIndexByRenderedItems(BuildContext viewportContext) {
    if (list.isEmpty) return;
    final viewportRenderObject = viewportContext.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      return;
    }

    final viewportOffset = viewportRenderObject.localToGlobal(Offset.zero);
    final viewportTop = viewportOffset.dy;
    final viewportBottom = viewportTop + viewportRenderObject.size.height;
    final viewportCenter = viewportTop + viewportRenderObject.size.height * 0.5;

    var bestIndex = -1;
    var bestDistance = double.infinity;
    var bestVisibleHeight = 0.0;

    for (var index = 0; index < list.length; index += 1) {
      final docId = list[index].docID;
      final itemContext = _agendaKeys[docId]?.currentContext;
      final itemRenderObject = itemContext?.findRenderObject();
      if (itemRenderObject is! RenderBox || !itemRenderObject.hasSize) {
        continue;
      }

      final itemOffset = itemRenderObject.localToGlobal(Offset.zero);
      final itemTop = itemOffset.dy;
      final itemBottom = itemTop + itemRenderObject.size.height;
      final visibleTop = itemTop > viewportTop ? itemTop : viewportTop;
      final visibleBottom =
          itemBottom < viewportBottom ? itemBottom : viewportBottom;
      final visibleHeight = visibleBottom - visibleTop;
      if (visibleHeight <= 0) continue;

      final itemCenter = itemTop + itemRenderObject.size.height * 0.5;
      final distance = (itemCenter - viewportCenter).abs();
      if (distance < bestDistance) {
        bestIndex = index;
        bestDistance = distance;
        bestVisibleHeight = visibleHeight;
      }
    }

    if (bestIndex < 0 || bestIndex >= list.length) return;
    final previous = centeredIndex.value;
    if (lastCenteredIndex != null &&
        lastCenteredIndex != bestIndex &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      disposeAgendaContentController(list[lastCenteredIndex!].docID);
    }
    centeredIndex.value = bestIndex;
    currentVisibleIndex.value = bestIndex;
    lastCenteredIndex = bestIndex;
    capturePendingCenteredEntry(preferredIndex: bestIndex);
    if (previous != bestIndex) {
      debugPrint(
        '[TagPostsCenter] source=rendered previous=$previous next=$bestIndex '
        'doc=${list[bestIndex].docID} visibleHeight=${bestVisibleHeight.toStringAsFixed(1)} '
        'distance=${bestDistance.toStringAsFixed(1)}',
      );
    }
  }

  int resolveResumeCenteredIndex() {
    if (list.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped = list.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < list.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= list.length) return;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
  }

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) {
    if (model != null) {
      final docId = model.docID.trim();
      _pendingCenteredDocId = docId.isEmpty ? null : docId;
      return;
    }
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= list.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = list[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }
}

TagPostsController ensureTagPostsController({required String tag}) =>
    _ensureTagPostsController(tag: tag);

TagPostsController? maybeFindTagPostsController({String? tag}) =>
    _maybeFindTagPostsController(tag: tag);
