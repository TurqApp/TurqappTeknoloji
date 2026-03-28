part of 'profile_controller.dart';

extension ProfileControllerSelectionPart on ProfileController {
  int _performResolveResumeCenteredIndex() {
    if (mergedPosts.isEmpty) return -1;
    final pendingIdentity = _pendingCenteredIdentity;
    if (pendingIdentity != null && pendingIdentity.isNotEmpty) {
      final pendingIndex = mergedPosts.indexWhere((entry) {
        final entryDocId = ((entry['docID'] as String?) ?? '').trim();
        final entryIsReshare = entry['isReshare'] == true;
        return mergedEntryIdentity(
              docId: entryDocId,
              isReshare: entryIsReshare,
            ) ==
            pendingIdentity;
      });
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < mergedPosts.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < mergedPosts.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _performResumeCenteredPost() {
    final expectedDocId = (lastCenteredIndex != null &&
            lastCenteredIndex! >= 0 &&
            lastCenteredIndex! < mergedPosts.length)
        ? (mergedPosts[lastCenteredIndex!]['docID'] as String?)
        : null;
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= mergedPosts.length) return;
    lastCenteredIndex = target;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    capturePendingCenteredEntry(preferredIndex: target);
    pausetheall.value = false;
    _invariantGuard.assertCenteredSelection(
      surface: 'profile',
      invariantKey: 'resume_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: mergedPosts
          .map((post) => (post['docID'] as String?) ?? '')
          .toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{'target': target},
    );
    if (postSelection.value == 0) {
      _performEnsureCenteredPlaybackForIndex(target);
    }
  }

  void _performCapturePendingCenteredEntry({int? preferredIndex}) {
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= mergedPosts.length) {
      _pendingCenteredIdentity = null;
      return;
    }
    final entry = mergedPosts[candidateIndex];
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) {
      _pendingCenteredIdentity = null;
      return;
    }
    _pendingCenteredIdentity = mergedEntryIdentity(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
  }

  void _performBindCacheWorkers() {
    _allPostsWorker =
        ever(allPosts, (_) => _performSchedulePersistPostCaches());
    _photosWorker = ever(photos, (_) => _performSchedulePersistPostCaches());
    _videosWorker = ever(videos, (_) => _performSchedulePersistPostCaches());
    _resharesWorker =
        ever(reshares, (_) => _performSchedulePersistPostCaches());
    _scheduledWorker =
        ever(scheduledPosts, (_) => _performSchedulePersistPostCaches());
    _mergedPostsWorker = everAll(
      [allPosts, reshares],
      (_) => _performRebuildMergedPosts(),
    );
    _performRebuildMergedPosts();
  }

  void _performRebuildMergedPosts() {
    if (allPosts.isEmpty && reshares.isEmpty) {
      mergedPosts.clear();
      _visibleFractions.clear();
      centeredIndex.value = -1;
      currentVisibleIndex.value = -1;
      return;
    }

    final combined = _profileRenderCoordinator.buildMergedEntries(
      allPosts: allPosts.toList(growable: false),
      reshares: reshares.toList(growable: false),
      reshareSortTimestampFor: reshareSortTimestampFor,
    );
    final patch = _profileRenderCoordinator.buildPatch(
      previous: mergedPosts.toList(growable: false),
      next: combined,
    );
    _profileRenderCoordinator.applyPatch(mergedPosts, patch);
    _visibleFractions.removeWhere((index, _) => index >= mergedPosts.length);
    if (centeredIndex.value < 0 || centeredIndex.value >= mergedPosts.length) {
      final target = _performResolveInitialCenteredIndex();
      if (target >= 0) {
        centeredIndex.value = target;
        currentVisibleIndex.value = target;
        lastCenteredIndex = target;
      }
    }
  }

  int _performResolveInitialCenteredIndex() {
    if (mergedPosts.isEmpty) return -1;
    final pendingIdentity = _pendingCenteredIdentity;
    if (pendingIdentity != null && pendingIdentity.isNotEmpty) {
      final pendingIndex = mergedPosts.indexWhere((entry) {
        final entryDocId = ((entry['docID'] as String?) ?? '').trim();
        final entryIsReshare = entry['isReshare'] == true;
        return mergedEntryIdentity(
              docId: entryDocId,
              isReshare: entryIsReshare,
            ) ==
            pendingIdentity;
      });
      if (pendingIndex >= 0) return pendingIndex;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < mergedPosts.length) {
      return lastCenteredIndex!;
    }
    return 0;
  }

  bool _performCanAutoplayMergedEntry(Map<String, dynamic> entry) {
    final post = entry['post'];
    if (post is! PostsModel) return false;
    if (post.deletedPost) return false;
    if (post.arsiv) return false;
    return post.hasPlayableVideo;
  }

  void _performOnPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (postSelection.value != 0) return;
    if (pausetheall.value || showPfImage.value) return;
    if (modelIndex < 0 || modelIndex >= mergedPosts.length) return;
    if (!_performCanAutoplayMergedEntry(mergedPosts[modelIndex])) return;

    final prev = _visibleFractions[modelIndex];
    if (FeedPlaybackSelectionPolicy.shouldIgnoreVisibilityUpdate(
      previousFraction: prev,
      visibleFraction: visibleFraction,
    )) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
    }

    _performScheduleVisibilityEvaluation();
  }

  void _performScheduleVisibilityEvaluation() {
    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(
      FeedPlaybackSelectionPolicy.evaluationDebounceDuration,
      _performEvaluateCenteredPlayback,
    );
  }

  void _performEvaluateCenteredPlayback() {
    if (mergedPosts.isEmpty) return;
    final targetIndex = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
      visibleFractions: _visibleFractions,
      currentIndex: centeredIndex.value,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: mergedPosts.length,
      canAutoplayIndex: (index) =>
          _performCanAutoplayMergedEntry(mergedPosts[index]),
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );

    if (targetIndex >= 0 && targetIndex < mergedPosts.length) {
      if (centeredIndex.value != targetIndex) {
        centeredIndex.value = targetIndex;
      }
      currentVisibleIndex.value = targetIndex;
      lastCenteredIndex = targetIndex;
      if (centeredIndex.value != targetIndex ||
          !_performIsPlaybackTargetCurrent(targetIndex)) {
        _performEnsureCenteredPlaybackForIndex(targetIndex);
      }
    } else {
      centeredIndex.value = -1;
    }
  }

  void _performSetPostSelection(int index) {
    postSelection.value = index;
    if (index != 0) {
      VideoStateManager.instance.pauseAllVideos(force: true);
    }
  }

  bool _performIsPlaybackTargetCurrent(int index) {
    if (index < 0 || index >= mergedPosts.length) return false;
    final entry = mergedPosts[index];
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) return false;
    final playbackKey = agendaInstanceTag(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
    return VideoStateManager.instance.isPlaybackTargetActive(playbackKey);
  }

  void _performEnsureCenteredPlaybackForIndex(int index) {
    if (postSelection.value != 0) return;
    if (pausetheall.value || showPfImage.value) return;
    if (index < 0 || index >= mergedPosts.length) return;
    final entry = mergedPosts[index];
    if (!_performCanAutoplayMergedEntry(entry)) return;
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) return;
    final playbackKey = agendaInstanceTag(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
    final manager = VideoStateManager.instance;
    final issuedAt = manager.activatePlaybackTargetIfReady(
      playbackKey,
      lastCommandDocId: _lastPlaybackCommandDocId,
      lastCommandAt: _lastPlaybackCommandAt,
    );
    if (issuedAt == null) return;
    _lastPlaybackCommandDocId = playbackKey;
    _lastPlaybackCommandAt = issuedAt;
  }

  GlobalKey _performGetPostKey({
    required String docId,
    required bool isReshare,
  }) {
    final identity = mergedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return _postKeys.putIfAbsent(
      identity,
      () => GlobalObjectKey(identity),
    );
  }

  String _performMergedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) {
    return '${isReshare ? 'reshare' : 'post'}_$docId';
  }

  int _performIndexOfMergedEntry({
    required String docId,
    required bool isReshare,
  }) {
    final identity = mergedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return mergedPosts.indexWhere((entry) {
      final entryDocId = ((entry['docID'] as String?) ?? '').trim();
      final entryIsReshare = entry['isReshare'] == true;
      return mergedEntryIdentity(
            docId: entryDocId,
            isReshare: entryIsReshare,
          ) ==
          identity;
    });
  }

  String _performAgendaInstanceTag({
    required String docId,
    required bool isReshare,
  }) {
    return 'profile_${isReshare ? 'reshare' : 'post'}_$docId';
  }

  void _performDisposeAgendaContentController(String docID) {
    final tags = <String>{
      agendaInstanceTag(docId: docID, isReshare: false),
      agendaInstanceTag(docId: docID, isReshare: true),
    };
    for (final tag in tags) {
      if (AgendaContentController.maybeFind(tag: tag) != null) {
        Get.delete<AgendaContentController>(tag: tag, force: true);
      }
    }
  }
}
