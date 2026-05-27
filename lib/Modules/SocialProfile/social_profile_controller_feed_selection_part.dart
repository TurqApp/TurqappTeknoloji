part of 'social_profile_controller.dart';

extension SocialProfileControllerFeedSelectionPart on SocialProfileController {
  bool _performShouldPreferImmediatePlaybackHandoff(int index) {
    if (!GetPlatform.isIOS) return false;
    final centered = centeredIndex.value;
    if (centered < 0) return false;
    return (index - centered).abs() <= 1;
  }

  static const int _defaultProfileWarmPlayableCount =
      StartupPreloadPolicy.aheadFirstSegmentCount;

  bool get _performUsesTightCellularWarmProfile =>
      StartupPreloadPolicy.useTightCellularWarmProfile(
        isAndroid: GetPlatform.isAndroid,
        isOnCellular:
            NetworkAwarenessService.maybeFind()?.isOnCellular ?? false,
      );

  void _performBootstrapFeedPlaybackAfterDataChange() {
    if (postSelection.value != 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (postSelection.value != 0) return;
      final activeEntries = combinedFeedEntries;
      if (activeEntries.isEmpty) {
        centeredIndex.value = -1;
        currentVisibleIndex.value = -1;
        lastCenteredIndex = null;
        _visibleFractions.clear();
        _visibleUpdatedAt.clear();
        _lastStartupWarmSignature = null;
        _lastPlaybackWarmSignature = null;
        return;
      }
      final target = resolveResumeCenteredIndex();
      if (target < 0 || target >= activeEntries.length) return;
      centeredIndex.value = target;
      currentVisibleIndex.value = target;
      lastCenteredIndex = target;
      capturePendingCenteredEntry(preferredIndex: target);
      _performWarmProfilePlaybackWindow(
        centered: target,
        phase: 'startup',
      );
      if (_performCanAutoplayCombinedEntry(activeEntries[target])) {
        _performEnsureCenteredPlaybackForIndex(target);
      } else {
        _performScheduleVisibilityEvaluation();
      }
    });
  }

  int _performResolveResumeCenteredIndex() {
    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    if (activeLength == 0) return -1;
    final pendingIdentity = _pendingCenteredIdentity;
    if (pendingIdentity != null && pendingIdentity.isNotEmpty) {
      final pendingIndex = postSelection.value == 0
          ? combinedFeedEntries.indexWhere((entry) {
              final entryDocId = ((entry['docID'] as String?) ?? '').trim();
              final entryIsReshare = entry['isReshare'] == true;
              return combinedEntryIdentity(
                    docId: entryDocId,
                    isReshare: entryIsReshare,
                  ) ==
                  pendingIdentity;
            })
          : allPosts
              .indexWhere((post) => 'post_${post.docID}' == pendingIdentity);
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < activeLength) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < activeLength) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _performResumeCenteredPost() {
    final activeCombinedEntries = postSelection.value == 0
        ? combinedFeedEntries
        : const <Map<String, dynamic>>[];
    final activeLength = postSelection.value == 0
        ? activeCombinedEntries.length
        : allPosts.length;
    final expectedDocId = (lastCenteredIndex != null &&
            lastCenteredIndex! >= 0 &&
            lastCenteredIndex! < activeLength)
        ? postSelection.value == 0
            ? ((activeCombinedEntries[lastCenteredIndex!]['docID']
                    as String?) ??
                '')
            : allPosts[lastCenteredIndex!].docID
        : null;
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= activeLength) return;
    lastCenteredIndex = target;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    capturePendingCenteredEntry(preferredIndex: target);
    surfacePlaybackSuspended.value = false;
    _invariantGuard.assertCenteredSelection(
      surface: 'social_profile',
      invariantKey: 'resume_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: postSelection.value == 0
          ? activeCombinedEntries
              .map((entry) => ((entry['docID'] as String?) ?? ''))
              .toList(growable: false)
          : allPosts.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );
    if (postSelection.value == 0) {
      _performEnsureCenteredPlaybackForIndex(target);
    }
  }

  void _performCapturePendingCenteredEntry({
    int? preferredIndex,
    PostsModel? model,
    bool isReshare = false,
  }) {
    if (model != null) {
      final docId = model.docID.trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = postSelection.value == 0
          ? combinedEntryIdentity(docId: docId, isReshare: isReshare)
          : 'post_$docId';
      return;
    }

    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= activeLength) {
      _pendingCenteredIdentity = null;
      return;
    }

    if (postSelection.value == 0) {
      final entry = combinedFeedEntries[candidateIndex];
      final docId = ((entry['docID'] as String?) ?? '').trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = combinedEntryIdentity(
        docId: docId,
        isReshare: entry['isReshare'] == true,
      );
      return;
    }

    final docId = allPosts[candidateIndex].docID.trim();
    _pendingCenteredIdentity = docId.isEmpty ? null : 'post_$docId';
  }

  String _performCombinedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) {
    return '${isReshare ? 'reshare' : 'post'}_$docId';
  }

  bool _performCanAutoplayCombinedEntry(Map<String, dynamic> entry) {
    final post = entry['post'];
    if (post is! PostsModel) return false;
    if (post.deletedPost) return false;
    if (post.arsiv) return false;
    return post.hasPlayableVideo;
  }

  void _performOnPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (postSelection.value != 0) return;
    if (surfacePlaybackSuspended.value || showPfImage.value) return;
    final activeEntries = combinedFeedEntries;
    if (modelIndex < 0 || modelIndex >= activeEntries.length) return;

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
        itemCount: activeEntries.length,
        canAutoplayIndex: (index) =>
            _performCanAutoplayCombinedEntry(activeEntries[index]),
        stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
        preferDominantVisibleIndexWhenNonPlayable: true,
      );
      if (previewTarget >= 0 && previewTarget < activeEntries.length) {
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
    if (postSelection.value != 0) return;
    if (surfacePlaybackSuspended.value || showPfImage.value) return;
    final activeEntries = combinedFeedEntries;
    if (activeEntries.isEmpty) return;
    final current = centeredIndex.value;
    final scrollDecision =
        FeedPlaybackSelectionPolicy.resolveDirectionalScrollDecision(
      isScrollActive: _feedScrollStartedAt != null,
      visibleFractions: _visibleFractions,
      currentIndex: current,
      scrollDirection: _feedScrollDirection,
      itemCount: activeEntries.length,
      canAutoplayIndex: (index) =>
          _performCanAutoplayCombinedEntry(activeEntries[index]),
      isPlaybackTargetCurrent: _performIsPlaybackTargetCurrent,
    );
    if (scrollDecision.hasTarget) {
      final targetIndex = scrollDecision.targetIndex;
      debugPrint(
        '[ProfilePlaybackDecision] action=${scrollDecision.action} '
        'surface=social_profile current=$current target=$targetIndex '
        'direction=$_feedScrollDirection '
        'changed=${centeredIndex.value != targetIndex} '
        'visible=${_visibleFractions.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').join(',')}',
      );
      final centeredChanged = centeredIndex.value != targetIndex;
      if (centeredChanged) {
        centeredIndex.value = targetIndex;
      }
      currentVisibleIndex.value = targetIndex;
      lastCenteredIndex = targetIndex;
      _performCapturePendingCenteredEntry(preferredIndex: targetIndex);
      if (scrollDecision.shouldEnsurePlayback) {
        _performEnsureCenteredPlaybackForIndex(targetIndex);
      }
      return;
    }

    final decision = FeedPlaybackSelectionPolicy.resolvePlaybackDecision(
      visibleFractions: _visibleFractions,
      visibleUpdatedAt: _visibleUpdatedAt,
      currentIndex: current,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: activeEntries.length,
      canAutoplayIndex: (index) =>
          _performCanAutoplayCombinedEntry(activeEntries[index]),
      isPlaybackTargetCurrent: _performIsPlaybackTargetCurrent,
      playbackKeyForIndex: (index) {
        final entry = activeEntries[index];
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
        'current=$current target=$targetIndex changed=${centeredIndex.value != targetIndex} '
        'visible=${_visibleFractions.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').join(',')}',
      );
      final centeredChanged = centeredIndex.value != targetIndex;
      if (centeredChanged) {
        centeredIndex.value = targetIndex;
      }
      currentVisibleIndex.value = targetIndex;
      lastCenteredIndex = targetIndex;
      _performCapturePendingCenteredEntry(preferredIndex: targetIndex);
      if (decision.shouldEnsurePlayback) {
        _performEnsureCenteredPlaybackForIndex(targetIndex);
      }
    } else {
      centeredIndex.value = -1;
      currentVisibleIndex.value = -1;
      VideoStateManager.instance.pauseAllVideos(force: true);
    }
  }

  List<Map<String, dynamic>> _performCombinedFeedEntries() {
    final combinedPosts = <Map<String, dynamic>>[];

    for (final post in allPosts) {
      combinedPosts.add(<String, dynamic>{
        'docID': post.docID,
        'post': post,
        'isReshare': false,
        'timestamp': post.timeStamp,
      });
    }

    for (final reshare in reshares) {
      combinedPosts.add(<String, dynamic>{
        'docID': reshare.docID,
        'post': reshare,
        'isReshare': true,
        'timestamp': reshare.timeStamp,
      });
    }

    combinedPosts.sort(
      (a, b) => (b['timestamp'] as num).compareTo(a['timestamp'] as num),
    );
    return combinedPosts;
  }

  int _performIndexOfCombinedEntry({
    required String docId,
    required bool isReshare,
  }) {
    final identity = combinedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return combinedFeedEntries.indexWhere((entry) {
      final entryDocId = ((entry['docID'] as String?) ?? '').trim();
      final entryIsReshare = entry['isReshare'] == true;
      return combinedEntryIdentity(
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
    return 'social_${isReshare ? 'reshare' : 'post'}_$docId';
  }

  Future<void> _performDisposeAgendaContentController(String docID) async {
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

  bool _performIsPlaybackTargetCurrent(int index) {
    final activeEntries = combinedFeedEntries;
    if (index < 0 || index >= activeEntries.length) return false;
    final entry = activeEntries[index];
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
    if (showPfImage.value) return;
    final activeEntries = combinedFeedEntries;
    if (index < 0 || index >= activeEntries.length) return;
    _performWarmProfilePlaybackWindow(
      centered: index,
      phase: 'playback_horizon',
    );
    final entry = activeEntries[index];
    if (!_performCanAutoplayCombinedEntry(entry)) return;
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) return;
    _performCapturePendingCenteredEntry(preferredIndex: index);
    final playbackKey = agendaInstanceTag(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
    final manager = VideoStateManager.instance;
    final readyForImmediateHandoff =
        manager.canResumePlaybackFor(playbackKey) ||
            _performShouldPreferImmediatePlaybackHandoff(index);
    debugPrint(
      '[ProfilePlaybackTarget] action=activate surface=social_profile '
      'index=$index doc=$docId key=$playbackKey '
      'currentOwner=${manager.currentPlayingDocID ?? ''} '
      'targetOwner=${manager.targetPlaybackDocID ?? ''} '
      'readyForImmediateHandoff=$readyForImmediateHandoff '
      'centered=${centeredIndex.value} visible=${currentVisibleIndex.value} '
      'route=${Get.currentRoute}',
    );
    final issuedAt = manager.activatePlaybackTargetIfReady(
      playbackKey,
      lastCommandDocId: _lastPlaybackCommandDocId,
      lastCommandAt: _lastPlaybackCommandAt,
      minInterval: GetPlatform.isIOS && readyForImmediateHandoff
          ? Duration.zero
          : const Duration(milliseconds: 120),
    );
    if (issuedAt == null) {
      debugPrint(
        '[ProfilePlaybackTarget] action=activate_miss surface=social_profile '
        'index=$index doc=$docId key=$playbackKey '
        'currentOwner=${manager.currentPlayingDocID ?? ''} '
        'targetOwner=${manager.targetPlaybackDocID ?? ''} '
        'readyForImmediateHandoff=$readyForImmediateHandoff',
      );
      return;
    }
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
    final activeEntries = combinedFeedEntries;
    if (activeEntries.isEmpty) return;
    if (centered < 0 || centered >= activeEntries.length) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;
    final warmPosts = _resolveProfileWarmPosts(
      centered: centered,
      maxCount: StartupPreloadPolicy.warmPlayableCount(
        _defaultProfileWarmPlayableCount,
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
          (((activeEntries[centered]['docID'] as String?) ?? '').trim());
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
      final playableOffset = i;
      final readySegments =
          _profileReadySegmentsForPlayableOffset(playableOffset);
      if (readySegments <= 0) continue;
      prefetch.boostDoc(
        warmPosts[i].docID,
        readySegments: readySegments,
      );
      warmLogs.add(
        '${i + 1}:${warmPosts[i].docID}:offset=$playableOffset:segments=$readySegments',
      );
    }
    if (warmLogs.isEmpty) return;
    debugPrint(
      '[ProfileOnYukleme] phase=$phase centered=$centered '
      'current=$currentIndex userId=$userID lastCentered=$lastCenteredIndex '
      'pending=${_pendingCenteredIdentity ?? ''} '
      'entries=${warmLogs.join(' | ')}',
    );
  }

  List<PostsModel> _resolveProfileWarmPosts({
    required int centered,
    required int maxCount,
  }) {
    final activeEntries = combinedFeedEntries;
    if (activeEntries.isEmpty || maxCount <= 0) {
      return const <PostsModel>[];
    }
    final collected = <PostsModel>[];
    final seenDocIds = <String>{};

    void addEntryAt(int index) {
      if (index < 0 || index >= activeEntries.length) return;
      final entry = activeEntries[index];
      if (!_performCanAutoplayCombinedEntry(entry)) return;
      final post = entry['post'];
      if (post is! PostsModel) return;
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenDocIds.add(docId)) return;
      if (post.playbackUrl.trim().isEmpty) return;
      collected.add(post);
    }

    addEntryAt(centered);
    for (var index = centered + 1;
        index < activeEntries.length && collected.length < maxCount;
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
    if (normalizedAnchorDocId.isEmpty || combinedFeedEntries.isEmpty) return;
    final anchorIndex = combinedFeedEntries.indexWhere((entry) {
      final docId = ((entry['docID'] as String?) ?? '').trim();
      return docId == normalizedAnchorDocId;
    });
    if (anchorIndex < 0 || anchorIndex >= combinedFeedEntries.length) return;

    var nextPlayableIndex = -1;
    for (var index = anchorIndex + 1;
        index < combinedFeedEntries.length;
        index++) {
      if (!_performCanAutoplayCombinedEntry(combinedFeedEntries[index])) {
        continue;
      }
      nextPlayableIndex = index;
      break;
    }
    if (nextPlayableIndex < 0) return;

    final nextPost = combinedFeedEntries[nextPlayableIndex]['post'];
    if (nextPost is! PostsModel) return;
    PlaybackStartHandoffService.instance.notifyPlaybackStarted(
      surface: 'social_profile',
      anchorKey: normalizedAnchorDocId,
      warmNext: () {
        const readySegments = StartupPreloadPolicy.activeReadySegments;
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
          '[ProfileNextWarm] status=boost surface=social_profile '
          'source=playback_start anchor=$anchorIndex next=$nextPlayableIndex '
          'doc=${nextPost.docID} segments=$readySegments',
        );
      },
    );
  }
}
