part of 'agenda_controller.dart';

extension AgendaControllerFeedPart on AgendaController {
  void noteStartupPromoRevealUserDrag() {
    if (_startupPromoRevealUnlockedByScroll) return;
    _startupPromoRevealSawUserDrag = true;
  }

  static const int _startupThumbnailPrefetchInitialCount = 5;
  static const int _startupThumbnailPrefetchRadius = 5;
  String _feedPlaybackHandleKeyForDoc(String docId) => 'feed:${docId.trim()}';

  static const Duration _startupPlaybackLockDuration =
      Duration(milliseconds: 900);
  static const Duration _androidCurrentRecoveryGrace =
      Duration(milliseconds: 1200);
  static const int _feedPlaybackBoostReadySegments = 2;
  static const int _feedPlaybackBoostLookAhead = 2;

  bool _reclaimFeedPlaybackFromExternalOwner(
    VideoStateManager manager, {
    required String source,
  }) {
    final currentPlayingDocId = manager.currentPlayingDocID;
    if (!_hasExternalPlaybackOwner(currentPlayingDocId)) return false;
    recordQALabPlaybackDispatch(
      surface: 'feed',
      stage: 'feed_reclaim_external_owner',
      metadata: <String, dynamic>{
        'source': source,
        'currentPlayingDocID': currentPlayingDocId ?? '',
        'centeredIndex': centeredIndex.value,
        'isPrimaryFeedRouteVisible': isPrimaryFeedRouteVisible,
        'canClaimPlaybackNow': canClaimPlaybackNow,
      },
    );
    manager.exitExclusiveMode();
    manager.pauseAllVideos(force: true);
    return true;
  }

  Duration _playbackReassertDelayForAttempt(int attempt) {
    if (!GetPlatform.isAndroid) {
      return attempt == 0
          ? const Duration(milliseconds: 260)
          : const Duration(milliseconds: 140);
    }
    return attempt == 0
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 120);
  }

  bool _hasExternalPlaybackOwner(String? playbackHandleKey) {
    final key = playbackHandleKey?.trim() ?? '';
    if (key.isEmpty) return false;
    return !key.startsWith('feed:');
  }

  bool get _canRetainStartupPlaybackLock {
    if (!GetPlatform.isIOS) return false;
    if (_qaScrollStartedAt != null || _qaLatestScrollToken.isNotEmpty) {
      return false;
    }
    final lockedDocId = _startupLockedFeedDocId?.trim() ?? '';
    final lockedAt = _startupPlaybackLockedAt;
    if (lockedDocId.isEmpty || lockedAt == null) {
      return false;
    }
    if (DateTime.now().difference(lockedAt) > _startupPlaybackLockDuration) {
      _startupLockedFeedDocId = null;
      _startupPlaybackLockedAt = null;
      return false;
    }
    return true;
  }

  void _lockStartupPlaybackTargetForIndex(int index) {
    if (!GetPlatform.isIOS) return;
    if (_qaScrollStartedAt != null || _qaLatestScrollToken.isNotEmpty) {
      return;
    }
    if (index < 0 || index >= agendaList.length) return;
    _startupLockedFeedDocId = agendaList[index].docID;
    _startupPlaybackLockedAt = DateTime.now();
  }

  void _ensureFeedPlaybackForIndex(int index) {
    if (!canClaimPlaybackNow) return;
    if (index < 0 || index >= agendaList.length) return;
    final post = agendaList[index];
    if (!_canAutoplayVideoPost(post)) return;
    _boostFeedPlaybackHorizon(index);
    final playbackKey = _feedPlaybackHandleKeyForDoc(post.docID);
    final manager = VideoStateManager.instance;
    _reclaimFeedPlaybackFromExternalOwner(
      manager,
      source: 'ensure_feed_playback',
    );
    final now = DateTime.now();
    final pendingPlay = manager.hasPendingPlayFor(playbackKey);
    final canAttemptCurrentRecovery = !GetPlatform.isAndroid ||
        _lastPlaybackCommandDocId != playbackKey ||
        _lastPlaybackCommandAt == null ||
        now.difference(_lastPlaybackCommandAt!) > _androidCurrentRecoveryGrace;
    final needsCurrentRecovery = !pendingPlay &&
        canAttemptCurrentRecovery &&
        manager.currentPlayingDocID == playbackKey &&
        !manager.isPlaybackTargetActive(playbackKey);
    final shouldIssueImmediateCommand = needsCurrentRecovery ||
        (!pendingPlay &&
            manager.currentPlayingDocID != playbackKey &&
            (_lastPlaybackCommandDocId != playbackKey ||
                _lastPlaybackCommandAt == null ||
                now.difference(_lastPlaybackCommandAt!) >
                    const Duration(milliseconds: 120)));
    if (shouldIssueImmediateCommand) {
      final readyForImmediateHandoff =
          manager.canResumePlaybackFor(playbackKey);
      recordQALabPlaybackDispatch(
        surface: 'feed',
        stage: needsCurrentRecovery
            ? 'feed_reassert_only_this'
            : (readyForImmediateHandoff
                ? 'feed_play_only_this'
                : 'feed_defer_play_only_this'),
        metadata: <String, dynamic>{
          'docId': post.docID,
          'index': index,
          'currentPlayingDocID': manager.currentPlayingDocID ?? '',
          'readyForImmediateHandoff': readyForImmediateHandoff,
          'needsCurrentRecovery': needsCurrentRecovery,
          'pendingPlay': pendingPlay,
        },
      );
      final issuedAt = manager.activatePlaybackTargetIfReady(
        playbackKey,
        lastCommandDocId: _lastPlaybackCommandDocId,
        lastCommandAt: _lastPlaybackCommandAt,
      );
      if (issuedAt != null) {
        _lastPlaybackCommandDocId = playbackKey;
        _lastPlaybackCommandAt = issuedAt;
      }
    }
    if (needsCurrentRecovery) {
      _schedulePlaybackReassert(
        index: index,
        docId: post.docID,
        manager: manager,
      );
    }
  }

  void _bindCenteredIndexListener() {
    ever<int>(centeredIndex, (newIndex) {
      final videoManager = VideoStateManager.instance;
      final preserveExternalPlayback = _hasExternalPlaybackOwner(
        videoManager.currentPlayingDocID,
      );
      _notifyPlaybackRowUpdates(newIndex);

      if (playbackSuspended.value) {
        _cancelPendingPlaybackReassert();
        videoManager.pauseAllVideos(force: true);
        return;
      }

      if (!isPrimaryFeedRouteVisible) {
        _cancelPendingPlaybackReassert();
        if (!preserveExternalPlayback) {
          videoManager.pauseAllVideos(force: true);
        }
        return;
      }

      if (newIndex == -1) {
        _cancelPendingPlaybackReassert();
        if (preserveExternalPlayback && canClaimPlaybackNow) {
          _reclaimFeedPlaybackFromExternalOwner(
            videoManager,
            source: 'centered_index_empty',
          );
        } else if (!preserveExternalPlayback) {
          videoManager.pauseAllVideos();
        }
        return;
      }

      if (newIndex >= 0 && newIndex < agendaList.length) {
        final centeredPost = agendaList[newIndex];
        if (_canAutoplayVideoPost(centeredPost)) {
          _ensureFeedPlaybackForIndex(newIndex);
        } else {
          _cancelPendingPlaybackReassert();
          if (preserveExternalPlayback && canClaimPlaybackNow) {
            _reclaimFeedPlaybackFromExternalOwner(
              videoManager,
              source: 'centered_index_non_playable',
            );
          } else {
            videoManager.pauseAllVideos();
          }
        }
      }

      _scheduleFeedPrefetch();
    });
  }

  void _scheduleFeedPrefetch({int attempt = 0}) {
    final readyForFeedPrefetch = !isLoading.value &&
        lastCenteredIndex != null &&
        renderFeedEntries.isNotEmpty &&
        centeredIndex.value >= 0;
    _feedPrefetchDebounce?.cancel();
    if (!readyForFeedPrefetch) {
      if (attempt >= 8) return;
      _feedPrefetchDebounce = Timer(const Duration(milliseconds: 320), () {
        _scheduleFeedPrefetch(attempt: attempt + 1);
      });
      return;
    }

    _prefetchCurrentPoster();
    _prefetchUpcomingImages();
    _prefetchThumbnailBatches();
    final centered = centeredIndex.value;
    if (centered >= 0 && centered < agendaList.length) {
      _boostFeedPlaybackHorizon(centered);
    }
    _feedPrefetchDebounce = Timer(const Duration(milliseconds: 240), () {
      _updateFeedPrefetchQueue();
    });
  }

  void _boostFeedPlaybackHorizon(int centered) {
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null || agendaList.isEmpty) return;
    final startupReadyThreshold = ReadBudgetRegistry.feedReadyForNavCount > 10
        ? ReadBudgetRegistry.feedReadyForNavCount
        : 10;
    final startupWindowStabilizing =
        prefetch.feedReadyCount < startupReadyThreshold;
    final maxBoosted =
        startupWindowStabilizing ? 1 : (_feedPlaybackBoostLookAhead + 1);
    final readySegments =
        startupWindowStabilizing ? 1 : _feedPlaybackBoostReadySegments;
    var boosted = 0;
    for (int i = centered; i < agendaList.length; i++) {
      final post = agendaList[i];
      if (!_canAutoplayVideoPost(post)) continue;
      prefetch.boostDoc(
        post.docID,
        readySegments: readySegments,
      );
      boosted++;
      if (boosted >= maxBoosted) {
        break;
      }
    }
  }

  void _prefetchCurrentPoster() {
    if (agendaList.isEmpty) return;
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final post = agendaList[current];
    for (final posterUrl in post.preferredVideoPosterUrls) {
      TurqImageCacheManager.warmUrl(posterUrl).ignore();
    }
    if (post.img.isNotEmpty) {
      TurqImageCacheManager.warmUrl(post.img.first).ignore();
    }
  }

  void _updateFeedPrefetchQueue() {
    if (agendaList.isEmpty) return;

    _prefetchThumbnailBatches();
    _prefetchUpcomingImages();

    final videoPosts =
        agendaList.where((p) => _canAutoplayVideoPost(p)).toList();
    FeedSurfaceRegistry.recordVideoDocIds(
      videoPosts.map((post) => post.docID),
    );
    if (videoPosts.isEmpty) return;

    int safeCurrent = 0;
    final centered = centeredIndex.value;
    if (centered >= 0 && centered < agendaList.length) {
      final centeredDocID = agendaList[centered].docID;
      final mapped = videoPosts.indexWhere((p) => p.docID == centeredDocID);
      if (mapped >= 0) {
        safeCurrent = mapped;
      } else {
        int beforeCount = 0;
        for (int i = 0; i < centered; i++) {
          if (_canAutoplayVideoPost(agendaList[i])) beforeCount++;
        }
        safeCurrent = beforeCount.clamp(0, videoPosts.length - 1);
      }
    }
    final prefetch = maybeFindPrefetchScheduler();
    final startupReadyThreshold = ReadBudgetRegistry.feedReadyForNavCount > 10
        ? ReadBudgetRegistry.feedReadyForNavCount
        : 10;
    if (prefetch != null && prefetch.feedReadyCount < startupReadyThreshold) {
      return;
    }
    try {
      prefetch?.updateFeedQueueForPosts(
        videoPosts,
        safeCurrent,
      );
    } catch (_) {}
  }

  void primeInitialCenteredPost() {
    final target = _agendaFeedApplicationService.resolveInitialCenteredIndex(
      agendaList: agendaList.toList(growable: false),
      pendingCenteredDocId: _pendingCenteredDocId,
      lastCenteredIndex: lastCenteredIndex,
      canAutoplayPost: _canAutoplayVideoPost,
    );
    if (target < 0 || target >= agendaList.length) return;
    final expectedDocId = _pendingCenteredDocId;
    centeredIndex.value = target;
    lastCenteredIndex = target;
    _lockStartupPlaybackTargetForIndex(target);
    _pendingCenteredDocId = null;
    _invariantGuard.assertCenteredSelection(
      surface: 'feed',
      invariantKey: 'prime_initial_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: agendaList.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );
    if (!pauseAll.value && canClaimPlaybackNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed ||
            pauseAll.value ||
            !canClaimPlaybackNow ||
            !isPrimaryFeedRouteVisible ||
            centeredIndex.value != target ||
            target < 0 ||
            target >= agendaList.length) {
          return;
        }
        if (!_canAutoplayVideoPost(agendaList[target])) {
          return;
        }
        final post = agendaList[target];
        _ensureFeedPlaybackForIndex(target);
        _schedulePlaybackReassert(
          index: target,
          docId: post.docID,
          manager: VideoStateManager.instance,
        );
        _scheduleStartupAutoplayKick(
          index: target,
          docId: post.docID,
        );
      });
    }
  }

  void resumeFeedPlayback() {
    if (!canClaimPlaybackNow) return;
    if (agendaList.isEmpty) return;

    pauseAll.value = false;
    final pendingCenteredDocId = _pendingCenteredDocId?.trim() ?? '';
    final expectedDocId =
        pendingCenteredDocId.isNotEmpty ? pendingCenteredDocId : null;
    int target = _agendaFeedApplicationService.resolveResumeIndex(
      agendaList: agendaList.toList(growable: false),
      pendingCenteredDocId: pendingCenteredDocId,
      lastCenteredIndex: lastCenteredIndex,
      centeredIndex: centeredIndex.value,
      visibleFractions: Map<int, double>.from(_visibleFractions),
      canAutoplayPost: _canAutoplayVideoPost,
    );

    if (target < 0 || target >= agendaList.length) return;
    lastCenteredIndex = target;
    final centeredChanged = centeredIndex.value != target;
    if (centeredChanged) {
      centeredIndex.value = target;
    }
    _lockStartupPlaybackTargetForIndex(target);
    _pendingCenteredDocId = null;
    _invariantGuard.assertCenteredSelection(
      surface: 'feed',
      invariantKey: 'resume_feed_playback',
      centeredIndex: centeredIndex.value,
      docIds: agendaList.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );

    if (!centeredChanged) {
      _ensureFeedPlaybackForIndex(target);
    }
  }

  void _prefetchUpcomingImages() {
    if (agendaList.isEmpty) return;
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final start = max(0, current - 1);
    final end = (current + 4).clamp(0, agendaList.length);
    for (int i = start; i < end; i++) {
      final post = agendaList[i];
      if (post.img.isNotEmpty) {
        TurqImageCacheManager.warmUrl(post.img.first).ignore();
      }
      for (final posterUrl in post.preferredVideoPosterUrls) {
        TurqImageCacheManager.warmUrl(posterUrl).ignore();
      }
    }
  }

  void _prefetchThumbnailBatches() {
    if (agendaList.isEmpty) return;
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final start = max(
      0,
      current < _startupThumbnailPrefetchInitialCount
          ? 0
          : current - _startupThumbnailPrefetchRadius,
    );
    final end =
        min(agendaList.length, current + _startupThumbnailPrefetchRadius + 1);
    for (int i = start; i < end; i++) {
      final post = agendaList[i];
      if (!_prefetchedThumbnailDocIds.add(post.docID)) {
        continue;
      }
      if (post.img.isNotEmpty) {
        TurqImageCacheManager.warmUrl(post.img.first).ignore();
      }
      for (final previewUrl in post.preferredVideoPosterUrls) {
        TurqImageCacheManager.warmUrl(previewUrl).ignore();
      }
    }

    _prefetchedThumbnailPostCount = max(_prefetchedThumbnailPostCount, end);
    _warmReplayAdsForPreparedWindow(end - start);
  }

  void _warmReplayAdsForPreparedWindow(int preparedPostCount) {
    if (preparedPostCount <= 0) return;
    final prefetch = maybeFindPrefetchScheduler();
    final readyThreshold = ReadBudgetRegistry.feedReadyForNavCount;
    final startupWindowStabilizing =
        prefetch == null || prefetch.feedReadyCount < readyThreshold;
    if (startupWindowStabilizing) return;
    final targetAds = min(4, max(2, (preparedPostCount / 12).ceil()));
    unawaited(
      ensureAdmobBannerWarmupService().warmForSurfaceEntry(
        surfaceKey: 'feed:replay_overlay',
        targetCount: targetAds,
      ),
    );
  }

  void ensureFeedCacheWarm() {
    _scheduleFeedPrefetch();
  }

  void _schedulePlaybackReassert({
    required int index,
    required String docId,
    required VideoStateManager manager,
    int attempt = 0,
  }) {
    _playbackReassertTimer?.cancel();
    _playbackReassertTimer = Timer(
      _playbackReassertDelayForAttempt(attempt),
      () {
        if (!canClaimPlaybackNow) return;
        if (centeredIndex.value != index) return;
        if (index < 0 || index >= agendaList.length) return;
        if (agendaList[index].docID != docId) return;
        final playbackKey = _feedPlaybackHandleKeyForDoc(docId);
        if (manager.isPlaybackTargetActive(playbackKey)) return;
        final pendingPlay = manager.hasPendingPlayFor(playbackKey);
        if (pendingPlay) {
          if (attempt < 3) {
            _schedulePlaybackReassert(
              index: index,
              docId: docId,
              manager: manager,
              attempt: attempt + 1,
            );
          }
          return;
        }
        final issuedAt = manager.activatePlaybackTargetIfReady(
          playbackKey,
          lastCommandDocId: _lastPlaybackCommandDocId,
          lastCommandAt: _lastPlaybackCommandAt,
          minInterval: attempt == 0
              ? const Duration(milliseconds: 120)
              : const Duration(milliseconds: 80),
        );
        if (issuedAt != null) {
          _lastPlaybackCommandDocId = playbackKey;
          _lastPlaybackCommandAt = issuedAt;
          return;
        }
        final shouldRetry = attempt < 3 &&
            (manager.currentPlayingDocID == playbackKey ||
                !manager.canResumePlaybackFor(playbackKey) ||
                manager.hasPendingPlayFor(playbackKey));
        if (shouldRetry) {
          _schedulePlaybackReassert(
            index: index,
            docId: docId,
            manager: manager,
            attempt: attempt + 1,
          );
        }
      },
    );
  }

  void _scheduleStartupAutoplayKick({
    required int index,
    required String docId,
  }) {
    if (!GetPlatform.isAndroid) return;
    final playbackKey = _feedPlaybackHandleKeyForDoc(docId);
    for (final delay in const <Duration>[
      Duration(milliseconds: 900),
      Duration(milliseconds: 2200),
      Duration(milliseconds: 3800),
    ]) {
      Future.delayed(delay, () {
        if (isClosed ||
            pauseAll.value ||
            !canClaimPlaybackNow ||
            !isPrimaryFeedRouteVisible ||
            centeredIndex.value != index ||
            index < 0 ||
            index >= agendaList.length ||
            agendaList[index].docID != docId) {
          return;
        }
        final manager = VideoStateManager.instance;
        if (manager.isPlaybackTargetActive(playbackKey)) {
          return;
        }
        final resumed = manager.resumeCurrentPlaybackIfReady(playbackKey);
        if (!resumed) {
          _ensureFeedPlaybackForIndex(index);
        }
      });
    }
  }

  void _cancelPendingPlaybackReassert() {
    _playbackReassertTimer?.cancel();
    _playbackReassertTimer = null;
  }

  String feedPlaybackRowUpdateId(String docId) => 'feed-playback-row-$docId';

  void _notifyPlaybackRowUpdates(int newIndex) {
    final ids = <String>{};
    final previousDocId = _lastPlaybackRowUpdateDocId?.trim() ?? '';
    if (previousDocId.isNotEmpty) {
      ids.add(feedPlaybackRowUpdateId(previousDocId));
    }
    String? nextDocId;
    if (newIndex >= 0) {
      nextDocId = agendaList[newIndex].docID;
      ids.add(feedPlaybackRowUpdateId(nextDocId));
    }
    _lastPlaybackRowUpdateDocId = nextDocId;
    if (ids.isNotEmpty) {
      update(ids.toList(growable: false));
    }
  }

  bool _isPlaybackTargetCurrent(int index) {
    if (index < 0 || index >= agendaList.length) return false;
    return VideoStateManager.instance.isPlaybackTargetActive(
      _feedPlaybackHandleKeyForDoc(agendaList[index].docID),
    );
  }

  GlobalKey getAgendaKeyForDoc(String docID) {
    return _agendaKeys.putIfAbsent(
      docID,
      () => GlobalObjectKey("agenda_$docID"),
    );
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;
    final now = DateTime.now();
    final scrollDelta = (currentOffset - lastOffset).abs();
    final startupLockActive =
        GetPlatform.isIOS && _canRetainStartupPlaybackLock;
    // Ignore small cold-start layout/inset jitters on iOS while the initial
    // autoplay target is locked. A real user scroll quickly exceeds this.
    final startupUnlockThreshold = startupLockActive ? 4.0 : 1.0;
    final hasMeaningfulScrollMovement =
        currentOffset.abs() > startupUnlockThreshold ||
            scrollDelta > startupUnlockThreshold;
    if (_qaScrollStartedAt == null) {
      if (!hasMeaningfulScrollMovement) {
        lastOffset = currentOffset;
        return;
      }
      _startupLockedFeedDocId = null;
      _startupPlaybackLockedAt = null;
      _qaScrollStartedAt = now;
      _qaScrollStartOffset = currentOffset;
      _qaActiveScrollToken =
          'feed-${now.microsecondsSinceEpoch}-${_qaScrollSequence++}';
      recordQALabScrollEvent(
        surface: 'feed',
        phase: 'start',
        metadata: <String, dynamic>{
          'scrollToken': _qaActiveScrollToken,
          'offset': currentOffset,
          'count': agendaList.length,
          'centeredIndex': centeredIndex.value,
          'centeredDocId': centeredIndex.value >= 0 &&
                  centeredIndex.value < agendaList.length
              ? agendaList[centeredIndex.value].docID
              : '',
        },
      );
    }
    bool shouldShowNavBar;

    if (currentOffset <= 0) {
      shouldShowNavBar = true;
    } else {
      if (currentOffset > lastOffset) {
        shouldShowNavBar = false;
      } else if (currentOffset < lastOffset) {
        shouldShowNavBar = true;
      } else {
        shouldShowNavBar = navBarController.showBar.value;
      }
    }
    if (navBarController.showBar.value != shouldShowNavBar) {
      navBarController.showBar.value = shouldShowNavBar;
    }
    lastOffset = currentOffset;

    final centered = centeredIndex.value;
    final remainingAfterCentered = centered >= 0 && centered < agendaList.length
        ? agendaList.length - centered - 1
        : agendaList.length;

    if (agendaList.isNotEmpty &&
        scrollController.position.hasContentDimensions &&
        (scrollController.position.pixels >=
                scrollController.position.maxScrollExtent - 300 ||
            remainingAfterCentered <=
                ReadBudgetRegistry.feedBufferedFetchLimit)) {
      recordQALabScrollEvent(
        surface: 'feed',
        phase: 'near_end',
        metadata: <String, dynamic>{
          'scrollToken': _qaActiveScrollToken,
          'offset': currentOffset,
          'maxScrollExtent': scrollController.position.maxScrollExtent,
          'count': agendaList.length,
          'remainingAfterCentered': remainingAfterCentered,
        },
      );
      fetchAgendaBigData(
        pageLimit: ReadBudgetRegistry.feedBufferedFetchLimit,
        trigger: 'scroll_near_end',
      );
    }

    final shouldShowFab = currentOffset <= 1000;
    if (showFAB.value != shouldShowFab) {
      showFAB.value = shouldShowFab;
    }

    _scrollIdleDebounce?.cancel();
    _scrollIdleDebounce = Timer(
      const Duration(milliseconds: 220),
      () {
        final settledAt = DateTime.now();
        final settledOffset = scrollController.hasClients
            ? scrollController.offset
            : currentOffset;
        final scrollDistance = settledOffset - _qaScrollStartOffset;
        final shouldUnlockStartupPromoReveal =
            !_startupPromoRevealUnlockedByScroll &&
                _startupPromoRevealSawUserDrag &&
                _qaActiveScrollToken.isNotEmpty &&
                scrollDistance.abs() > 400.0;
        final centered = centeredIndex.value;
        final centeredDocId = centered >= 0 && centered < agendaList.length
            ? agendaList[centered].docID
            : '';
        if (shouldUnlockStartupPromoReveal) {
          _startupPromoRevealUnlockedByScroll = true;
          recordQALabFeedFetchEvent(
            stage: 'startup_promo_reveal_unlock',
            trigger: 'user_scroll_settled',
            metadata: <String, dynamic>{
              'scrollToken': _qaActiveScrollToken,
              'offset': settledOffset,
              'distance': scrollDistance,
              'durationMs': settledAt
                  .difference(_qaScrollStartedAt ?? settledAt)
                  .inMilliseconds,
              'centeredIndex': centered,
              'docId': centeredDocId,
              'count': agendaList.length,
            },
          );
        }
        recordQALabScrollEvent(
          surface: 'feed',
          phase: 'settled',
          metadata: <String, dynamic>{
            'scrollToken': _qaActiveScrollToken,
            'offset': settledOffset,
            'distance': scrollDistance,
            'durationMs': settledAt
                .difference(_qaScrollStartedAt ?? settledAt)
                .inMilliseconds,
            'centeredIndex': centered,
            'docId': centeredDocId,
            'count': agendaList.length,
            'startupPromoRevealUnlockedByScroll':
                _startupPromoRevealUnlockedByScroll,
            'startupPromoRevealSawUserDrag': _startupPromoRevealSawUserDrag,
          },
        );
        _qaLatestScrollToken = _qaActiveScrollToken;
        _qaScrollStartedAt = null;
        _qaScrollStartOffset = 0.0;
        _qaActiveScrollToken = '';
        _startupPromoRevealSawUserDrag = false;
        if (shouldUnlockStartupPromoReveal) {
          _scheduleStartupPromoReveal();
        }
        if (centered < 0 || centered >= agendaList.length) {
          resumeFeedPlayback();
        }
      },
    );
  }

  void disposeAgendaContentController(String docID) {
    if (AgendaContentController.maybeFind(tag: docID) != null) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController");
    }
  }

  void markHighlighted(List<String> docIDs, {Duration? keepFor}) {
    highlightDocIDs.addAll(docIDs);
    final d = keepFor ?? const Duration(seconds: 2);
    Future.delayed(d, () {
      highlightDocIDs.removeAll(docIDs);
    });
  }
}
