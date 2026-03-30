part of 'agenda_controller.dart';

extension AgendaControllerFeedPart on AgendaController {
  String _feedPlaybackHandleKeyForDoc(String docId) => 'feed:${docId.trim()}';

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
    return lockedDocId.isNotEmpty;
  }

  void _lockStartupPlaybackTargetForIndex(int index) {
    if (!GetPlatform.isIOS) return;
    if (_qaScrollStartedAt != null || _qaLatestScrollToken.isNotEmpty) {
      return;
    }
    if (index < 0 || index >= agendaList.length) return;
    _startupLockedFeedDocId = agendaList[index].docID;
  }

  int _resolveInitialAutoplayIndexFromFilteredEntries() {
    if (filteredFeedEntries.isEmpty || agendaList.isEmpty) return -1;
    for (final entry in filteredFeedEntries) {
      final model = entry['model'];
      if (model is! PostsModel) continue;
      if (!_canAutoplayVideoPost(model)) continue;
      final index = agendaList.indexWhere((post) => post.docID == model.docID);
      if (index >= 0) return index;
    }
    return -1;
  }

  void _ensureFeedPlaybackForIndex(int index) {
    if (!canClaimPlaybackNow) return;
    if (index < 0 || index >= agendaList.length) return;
    final post = agendaList[index];
    if (!_canAutoplayVideoPost(post)) return;
    final playbackKey = _feedPlaybackHandleKeyForDoc(post.docID);
    final manager = VideoStateManager.instance;
    final now = DateTime.now();
    final pendingPlay = manager.hasPendingPlayFor(playbackKey);
    final needsCurrentRecovery = !pendingPlay &&
        manager.currentPlayingDocID == playbackKey &&
        !manager.isPlaybackTargetActive(playbackKey);
    final shouldIssueImmediateCommand = needsCurrentRecovery ||
        (!pendingPlay &&
            manager.currentPlayingDocID != playbackKey &&
            (_lastPlaybackCommandDocId != playbackKey ||
                _lastPlaybackCommandAt == null ||
                now.difference(_lastPlaybackCommandAt!) >
                    const Duration(milliseconds: 180)));
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
    _schedulePlaybackReassert(
      index: index,
      docId: post.docID,
      manager: manager,
    );
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
        if (!preserveExternalPlayback) {
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
          videoManager.pauseAllVideos();
        }
      }

      _scheduleFeedPrefetch();
    });
  }

  void _scheduleFeedPrefetch() {
    _feedPrefetchDebounce?.cancel();
    _feedPrefetchDebounce = Timer(const Duration(milliseconds: 1400), () {
      _updateFeedPrefetchQueue();
    });
  }

  void _updateFeedPrefetchQueue() {
    if (agendaList.isEmpty) return;

    _prefetchThumbnailBatches();
    _prefetchUpcomingImages();

    final videoPosts =
        agendaList.where((p) => _canAutoplayVideoPost(p)).toList();
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
    final docIds = videoPosts.map((p) => p.docID).toList();

    try {
      maybeFindPrefetchScheduler()?.updateFeedQueue(docIds, safeCurrent);
    } catch (_) {}
  }

  void primeInitialCenteredPost() {
    final preferredFilteredIndex =
        (_pendingCenteredDocId?.trim().isNotEmpty ?? false) ||
                lastCenteredIndex != null
            ? -1
            : _resolveInitialAutoplayIndexFromFilteredEntries();
    final target = preferredFilteredIndex >= 0
        ? preferredFilteredIndex
        : _agendaFeedApplicationService.resolveInitialCenteredIndex(
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
    if (centeredIndex.value != target) {
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

    _ensureFeedPlaybackForIndex(target);
  }

  void _prefetchUpcomingImages() {
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final end = (current + 4).clamp(0, agendaList.length);
    for (int i = current + 1; i < end; i++) {
      final post = agendaList[i];
      if (post.img.isNotEmpty) {
        TurqImageCacheManager.instance.getSingleFile(post.img.first).ignore();
      }
      if (post.thumbnail.isNotEmpty) {
        TurqImageCacheManager.instance.getSingleFile(post.thumbnail).ignore();
      }
    }
  }

  void _prefetchThumbnailBatches() {
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final targetCount =
        min(max(18, ((current ~/ 8) + 1) * 8), agendaList.length);
    if (targetCount <= _prefetchedThumbnailPostCount) return;

    for (int i = _prefetchedThumbnailPostCount; i < targetCount; i++) {
      final post = agendaList[i];
      final thumbnail = post.thumbnail.trim();
      final fallbackImage = post.img.isNotEmpty ? post.img.first.trim() : '';
      final previewUrl = thumbnail.isNotEmpty ? thumbnail : fallbackImage;
      if (previewUrl.isEmpty) continue;
      TurqImageCacheManager.instance.getSingleFile(previewUrl).ignore();
    }

    _prefetchedThumbnailPostCount = targetCount;
    _warmReplayAdsForPreparedWindow(targetCount);
  }

  void _warmReplayAdsForPreparedWindow(int preparedPostCount) {
    if (preparedPostCount <= 0) return;
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
      attempt == 0
          ? const Duration(milliseconds: 480)
          : const Duration(milliseconds: 220),
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
              ? const Duration(milliseconds: 180)
              : const Duration(milliseconds: 120),
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
    final hasMeaningfulScrollMovement =
        currentOffset.abs() > 1.0 || scrollDelta > 1.0;
    if (_qaScrollStartedAt == null) {
      if (!hasMeaningfulScrollMovement) {
        lastOffset = currentOffset;
        return;
      }
      _startupLockedFeedDocId = null;
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

    if (agendaList.isNotEmpty &&
        scrollController.position.hasContentDimensions &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300) {
      recordQALabScrollEvent(
        surface: 'feed',
        phase: 'near_end',
        metadata: <String, dynamic>{
          'scrollToken': _qaActiveScrollToken,
          'offset': currentOffset,
          'maxScrollExtent': scrollController.position.maxScrollExtent,
          'count': agendaList.length,
        },
      );
      fetchAgendaBigData(trigger: 'scroll_near_end');
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
        final centered = centeredIndex.value;
        final centeredDocId = centered >= 0 && centered < agendaList.length
            ? agendaList[centered].docID
            : '';
        recordQALabScrollEvent(
          surface: 'feed',
          phase: 'settled',
          metadata: <String, dynamic>{
            'scrollToken': _qaActiveScrollToken,
            'offset':
                scrollController.hasClients ? scrollController.offset : 0.0,
            'distance': (scrollController.hasClients
                    ? scrollController.offset
                    : currentOffset) -
                _qaScrollStartOffset,
            'durationMs': settledAt
                .difference(_qaScrollStartedAt ?? settledAt)
                .inMilliseconds,
            'centeredIndex': centered,
            'docId': centeredDocId,
            'count': agendaList.length,
          },
        );
        _qaLatestScrollToken = _qaActiveScrollToken;
        _qaScrollStartedAt = null;
        _qaScrollStartOffset = 0.0;
        _qaActiveScrollToken = '';
        if (centered >= 0 && centered < agendaList.length) {
          _ensureFeedPlaybackForIndex(centered);
        } else {
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
