part of 'profile_controller.dart';

extension ProfileControllerSelectionPart on ProfileController {
  static const int _profileWarmPlayableCount =
      StartupPreloadPolicy.aheadFirstSegmentCount;

  bool get _performUsesTightCellularWarmProfile =>
      StartupPreloadPolicy.useTightCellularWarmProfile(
        isAndroid: GetPlatform.isAndroid,
        isOnCellular:
            NetworkAwarenessService.maybeFind()?.isOnCellular ?? false,
      );

  bool _performShouldPreferImmediatePlaybackHandoff(int index) {
    if (!GetPlatform.isIOS) return false;
    final centered = centeredIndex.value;
    if (centered < 0) return false;
    return (index - centered).abs() <= 1;
  }

  void _performSetPrimarySurfaceActive(bool value) {
    if (_primarySurfaceActive == value) return;
    _primarySurfaceActive = value;
    if (value) {
      _performRebuildMergedPosts();
    }
  }

  bool get _canRetainStartupPlaybackLock {
    if (!GetPlatform.isIOS) return false;
    if (postSelection.value != 0) return false;
    if (_startupScrollStartedAt != null) return false;
    final lockedIdentity = _startupLockedIdentity?.trim() ?? '';
    return lockedIdentity.isNotEmpty;
  }

  void _lockStartupPlaybackIdentityForIndex(int index) {
    if (!GetPlatform.isIOS) return;
    if (postSelection.value != 0) return;
    if (index < 0 || index >= mergedPosts.length) return;
    final entry = mergedPosts[index];
    if (!_performCanAutoplayMergedEntry(entry)) return;
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) return;
    _startupLockedIdentity = mergedEntryIdentity(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
    _startupScrollStartedAt = null;
  }

  void _performBootstrapFeedPlaybackAfterDataChange() {
    if (postSelection.value != 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (postSelection.value != 0) return;
      final activeEntries = mergedPosts;
      if (activeEntries.isEmpty) {
        centeredIndex.value = -1;
        currentVisibleIndex.value = -1;
        lastCenteredIndex = null;
        return;
      }
      final target = resolveResumeCenteredIndex();
      if (target < 0 || target >= activeEntries.length) return;
      centeredIndex.value = target;
      currentVisibleIndex.value = target;
      lastCenteredIndex = target;
      capturePendingCenteredEntry(preferredIndex: target);
      _lockStartupPlaybackIdentityForIndex(target);
      _performWarmProfilePlaybackWindow(
        centered: target,
        phase: 'startup',
      );
      if (_performCanAutoplayMergedEntry(activeEntries[target])) {
        _performEnsureCenteredPlaybackForIndex(target);
      } else {
        _performScheduleVisibilityEvaluation();
      }
    });
  }

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
    _lockStartupPlaybackIdentityForIndex(target);
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
    if (!_primarySurfaceActive) return;
    if (allPosts.isEmpty && reshares.isEmpty) {
      mergedPosts.clear();
      _visibleFractions.clear();
      _visibleUpdatedAt.clear();
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

    final prev = _visibleFractions[modelIndex];
    if (FeedPlaybackSelectionPolicy.shouldIgnoreVisibilityUpdate(
      previousFraction: prev,
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

    if (_performUsesTightCellularWarmProfile &&
        visibleFraction >= FeedPlaybackSelectionPolicy.secondaryThreshold) {
      final previewTarget = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
        visibleFractions: _visibleFractions,
        currentIndex: centeredIndex.value,
        lastCenteredIndex: lastCenteredIndex,
        itemCount: mergedPosts.length,
        canAutoplayIndex: (index) =>
            _performCanAutoplayMergedEntry(mergedPosts[index]),
        stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
        preferDominantVisibleIndexWhenNonPlayable: true,
      );
      if (previewTarget >= 0 && previewTarget < mergedPosts.length) {
        _performWarmProfilePlaybackWindow(
          centered: previewTarget,
          phase: 'preview',
        );
      }
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
    if (_canRetainStartupPlaybackLock) {
      final lockedIdentity = _startupLockedIdentity?.trim() ?? '';
      final lockedIndex = mergedPosts.indexWhere((entry) {
        final entryDocId = ((entry['docID'] as String?) ?? '').trim();
        if (entryDocId.isEmpty) return false;
        return mergedEntryIdentity(
              docId: entryDocId,
              isReshare: entry['isReshare'] == true,
            ) ==
            lockedIdentity;
      });
      if (lockedIndex >= 0 &&
          lockedIndex < mergedPosts.length &&
          _performCanAutoplayMergedEntry(mergedPosts[lockedIndex])) {
        if (centeredIndex.value != lockedIndex) {
          centeredIndex.value = lockedIndex;
        }
        currentVisibleIndex.value = lockedIndex;
        lastCenteredIndex = lockedIndex;
        if (!_performIsPlaybackTargetCurrent(lockedIndex)) {
          _performEnsureCenteredPlaybackForIndex(lockedIndex);
        }
        return;
      }
    }
    final current = centeredIndex.value;
    final decision = FeedPlaybackSelectionPolicy.resolvePlaybackDecision(
      visibleFractions: _visibleFractions,
      visibleUpdatedAt: _visibleUpdatedAt,
      currentIndex: centeredIndex.value,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: mergedPosts.length,
      canAutoplayIndex: (index) =>
          _performCanAutoplayMergedEntry(mergedPosts[index]),
      isPlaybackTargetCurrent: _performIsPlaybackTargetCurrent,
      playbackKeyForIndex: (index) {
        final entry = mergedPosts[index];
        return agendaInstanceTag(
          docId: ((entry['docID'] as String?) ?? '').trim(),
          isReshare: entry['isReshare'] == true,
        );
      },
      lastCommandAt: _lastPlaybackCommandAt,
      lastCommandDocId: _lastPlaybackCommandDocId,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
      supportsSwitchRetention:
          PlaybackSurfacePolicy.supportsFeedSwitchRetention(
        platform: defaultTargetPlatform,
      ),
      preferDominantVisibleIndexWhenNonPlayable: true,
    );

    if (decision.hasTarget) {
      final targetIndex = decision.targetIndex;
      debugPrint(
        '[ProfilePlaybackDecision] action=${decision.action} '
        'surface=my_profile current=$current target=$targetIndex '
        'changed=${centeredIndex.value != targetIndex} '
        'visible=${_visibleFractions.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').join(',')}',
      );
      final centeredChanged = centeredIndex.value != targetIndex;
      if (centeredChanged) {
        centeredIndex.value = targetIndex;
      }
      currentVisibleIndex.value = targetIndex;
      lastCenteredIndex = targetIndex;
      if (decision.shouldEnsurePlayback) {
        _performEnsureCenteredPlaybackForIndex(targetIndex);
      }
    } else {
      centeredIndex.value = -1;
      currentVisibleIndex.value = -1;
      VideoStateManager.instance.pauseAllVideos(force: true);
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
    _performWarmProfilePlaybackWindow(
      centered: index,
      phase: 'playback_horizon',
    );
    final entry = mergedPosts[index];
    if (!_performCanAutoplayMergedEntry(entry)) return;
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) return;
    final playbackKey = agendaInstanceTag(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
    final manager = VideoStateManager.instance;
    final readyForImmediateHandoff =
        manager.canResumePlaybackFor(playbackKey) ||
            _performShouldPreferImmediatePlaybackHandoff(index);
    debugPrint(
      '[ProfilePlaybackTarget] action=activate index=$index '
      'doc=$docId key=$playbackKey currentOwner=${manager.currentPlayingDocID ?? ''} '
      'targetOwner=${manager.targetPlaybackDocID ?? ''} '
      'readyForImmediateHandoff=$readyForImmediateHandoff '
      'centered=${centeredIndex.value} visible=${currentVisibleIndex.value} '
      'route=${Get.currentRoute} nav=${maybeFindNavBarController()?.selectedIndex.value ?? -1}',
    );
    final issuedAt = manager.activatePlaybackTargetIfReady(
      playbackKey,
      lastCommandDocId: _lastPlaybackCommandDocId,
      lastCommandAt: _lastPlaybackCommandAt,
      minInterval: GetPlatform.isIOS && readyForImmediateHandoff
          ? Duration.zero
          : const Duration(milliseconds: 120),
    );
    if (issuedAt == null) return;
    _lastPlaybackCommandDocId = playbackKey;
    _lastPlaybackCommandAt = issuedAt;
    if (_performUsesTightCellularWarmProfile) {
      _performWarmProfilePlaybackWindow(
        centered: index,
        phase: 'target_playback',
      );
    }
  }

  void _performWarmProfilePlaybackWindow({
    required int centered,
    required String phase,
  }) {
    if (postSelection.value != 0) return;
    if (mergedPosts.isEmpty) return;
    if (centered < 0 || centered >= mergedPosts.length) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;
    final warmPosts = _resolveProfileWarmPosts(
      centered: centered,
      maxCount: StartupPreloadPolicy.warmPlayableCount(
        _profileWarmPlayableCount,
        isAndroid: GetPlatform.isAndroid,
        isOnCellular:
            NetworkAwarenessService.maybeFind()?.isOnCellular ?? false,
      ),
    );
    if (warmPosts.isEmpty) return;
    final signature =
        '$phase:$centered:${warmPosts.map((post) => post.docID).join(',')}';
    if (phase == 'startup') {
      if (_lastStartupWarmSignature == signature) return;
      _lastStartupWarmSignature = signature;
    } else {
      if (_lastPlaybackWarmSignature == signature) return;
      _lastPlaybackWarmSignature = signature;
    }
    final cacheManager = maybeFindSegmentCacheManager();
    if (cacheManager != null && cacheManager.isReady) {
      cacheManager.cachePostCards(warmPosts);
      for (final post in warmPosts) {
        final docId = post.docID.trim();
        final playbackUrl = post.playbackUrl.trim();
        if (docId.isEmpty || playbackUrl.isEmpty) continue;
        cacheManager.cacheHlsEntry(docId, playbackUrl);
      }
    }
    var currentIndex = warmPosts.indexWhere((post) {
      return post.docID.trim() ==
          (((mergedPosts[centered]['docID'] as String?) ?? '').trim());
    });
    if (currentIndex < 0) currentIndex = 0;
    unawaited(
      prefetch.updateFeedQueueForPosts(
        warmPosts,
        currentIndex,
        maxDocs: warmPosts.length,
      ),
    );
    final warmLogs = <String>[];
    for (var i = 0; i < warmPosts.length; i++) {
      final readySegments = _profileReadySegmentsForPlayableOffset(i);
      if (readySegments <= 0) continue;
      prefetch.boostDoc(
        warmPosts[i].docID,
        readySegments: readySegments,
      );
      warmLogs.add(
        '${i + 1}:${warmPosts[i].docID}:offset=$i:segments=$readySegments',
      );
    }
    if (warmLogs.isNotEmpty) {
      debugPrint(
        '[ProfileOnYukleme] phase=$phase centered=$centered '
        'current=$currentIndex entries=${warmLogs.join(' | ')}',
      );
    }
  }

  List<PostsModel> _resolveProfileWarmPosts({
    required int centered,
    required int maxCount,
  }) {
    if (mergedPosts.isEmpty || maxCount <= 0) {
      return const <PostsModel>[];
    }
    final collected = <PostsModel>[];
    final seenDocIds = <String>{};

    void addEntryAt(int index) {
      if (index < 0 || index >= mergedPosts.length) return;
      final entry = mergedPosts[index];
      if (!_performCanAutoplayMergedEntry(entry)) return;
      final post = entry['post'];
      if (post is! PostsModel) return;
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenDocIds.add(docId)) return;
      if (post.playbackUrl.trim().isEmpty) return;
      collected.add(post);
    }

    addEntryAt(centered);
    for (var index = centered + 1;
        index < mergedPosts.length && collected.length < maxCount;
        index++) {
      addEntryAt(index);
    }
    for (var index = centered - 1;
        index >= 0 && collected.length < maxCount;
        index--) {
      addEntryAt(index);
    }
    return collected;
  }

  int _profileReadySegmentsForPlayableOffset(int playableOffset) {
    return StartupPreloadPolicy.warmReadySegmentsForOffset(
      playableOffset,
      isAndroid: GetPlatform.isAndroid,
      isOnCellular: _performUsesTightCellularWarmProfile,
    );
  }

  void primeImmediateNextProfileAfterPlaybackStart(String anchorDocId) {
    final normalizedAnchorDocId = anchorDocId.trim();
    if (normalizedAnchorDocId.isEmpty || mergedPosts.isEmpty) return;
    final anchorIndex = mergedPosts.indexWhere((entry) {
      final docId = ((entry['docID'] as String?) ?? '').trim();
      return docId == normalizedAnchorDocId;
    });
    if (anchorIndex < 0 || anchorIndex >= mergedPosts.length) return;

    var nextPlayableIndex = -1;
    for (var index = anchorIndex + 1; index < mergedPosts.length; index++) {
      if (!_performCanAutoplayMergedEntry(mergedPosts[index])) continue;
      nextPlayableIndex = index;
      break;
    }
    if (nextPlayableIndex < 0) return;

    final nextPost = mergedPosts[nextPlayableIndex]['post'];
    if (nextPost is! PostsModel) return;
    final readySegments = StartupPreloadPolicy.readySegmentsForAheadOffset(1);
    maybeFindPrefetchScheduler()?.boostDoc(
      nextPost.docID,
      readySegments: readySegments,
    );
    for (final posterUrl in nextPost.preferredVideoPosterUrls) {
      TurqImageCacheManager.warmUrl(posterUrl).ignore();
    }
    final preview = nextPost.primaryImageUrl.trim();
    if (preview.isNotEmpty) {
      TurqImageCacheManager.warmUrl(preview).ignore();
    }
    debugPrint(
      '[ProfileNextWarm] status=boost surface=my_profile source=first_frame '
      'anchor=$anchorIndex next=$nextPlayableIndex '
      'doc=${nextPost.docID} segments=$readySegments',
    );
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
