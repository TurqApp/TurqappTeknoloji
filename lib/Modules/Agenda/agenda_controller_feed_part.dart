part of 'agenda_controller.dart';

extension AgendaControllerFeedPart on AgendaController {
  void _ensureFeedPlaybackForIndex(int index) {
    if (!canClaimPlaybackNow) return;
    if (index < 0 || index >= agendaList.length) return;
    final post = agendaList[index];
    if (!_canAutoplayVideoPost(post)) return;
    final manager = VideoStateManager.instance;
    final now = DateTime.now();
    final shouldIssueImmediateCommand =
        manager.currentPlayingDocID != post.docID &&
            (_lastPlaybackCommandDocId != post.docID ||
                _lastPlaybackCommandAt == null ||
                now.difference(_lastPlaybackCommandAt!) >
                    const Duration(milliseconds: 180));
    if (shouldIssueImmediateCommand) {
      final readyForImmediateHandoff = manager.canResumePlaybackFor(post.docID);
      recordQALabPlaybackDispatch(
        surface: 'feed',
        stage: manager.currentPlayingDocID == post.docID
            ? 'feed_reassert_only_this'
            : (readyForImmediateHandoff
                ? 'feed_play_only_this'
                : 'feed_defer_play_only_this'),
        metadata: <String, dynamic>{
          'docId': post.docID,
          'index': index,
          'currentPlayingDocID': manager.currentPlayingDocID ?? '',
          'readyForImmediateHandoff': readyForImmediateHandoff,
        },
      );
      if (manager.currentPlayingDocID == post.docID) {
        manager.reassertOnlyThis(post.docID);
        _lastPlaybackCommandDocId = post.docID;
        _lastPlaybackCommandAt = now;
      } else if (readyForImmediateHandoff) {
        final issuedAt = manager.claimPlaybackTargetIfReady(
          post.docID,
          lastCommandDocId: _lastPlaybackCommandDocId,
          lastCommandAt: _lastPlaybackCommandAt,
        );
        if (issuedAt != null) {
          _lastPlaybackCommandDocId = post.docID;
          _lastPlaybackCommandAt = issuedAt;
        }
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
      _notifyPlaybackRowUpdates(newIndex);

      if (playbackSuspended.value) {
        _cancelPendingPlaybackReassert();
        videoManager.pauseAllVideos(force: true);
        return;
      }

      if (!isPrimaryFeedRouteVisible) {
        _cancelPendingPlaybackReassert();
        videoManager.pauseAllVideos(force: true);
        return;
      }

      if (newIndex == -1) {
        _cancelPendingPlaybackReassert();
        videoManager.pauseAllVideos();
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
    final expectedDocId = _pendingCenteredDocId ??
        ((lastCenteredIndex != null &&
                lastCenteredIndex! >= 0 &&
                lastCenteredIndex! < agendaList.length)
            ? agendaList[lastCenteredIndex!].docID
            : null);
    int target = _agendaFeedApplicationService.resolveResumeIndex(
      agendaList: agendaList.toList(growable: false),
      pendingCenteredDocId: _pendingCenteredDocId,
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
  }) {
    _playbackReassertTimer?.cancel();
    _playbackReassertTimer = Timer(
      const Duration(milliseconds: 480),
      () {
        if (!canClaimPlaybackNow) return;
        if (centeredIndex.value != index) return;
        if (index < 0 || index >= agendaList.length) return;
        if (agendaList[index].docID != docId) return;
        if (manager.currentPlayingDocID == docId) return;
        manager.reassertOnlyThis(docId);
        _lastPlaybackCommandDocId = docId;
        _lastPlaybackCommandAt = DateTime.now();
      },
    );
  }

  void _cancelPendingPlaybackReassert() {
    _playbackReassertTimer?.cancel();
    _playbackReassertTimer = null;
  }

  String feedPlaybackRowUpdateId(int index) => 'feed-playback-row-$index';

  void _notifyPlaybackRowUpdates(int newIndex) {
    final ids = <String>{};
    if (_lastPlaybackRowUpdateIndex >= 0) {
      ids.add(feedPlaybackRowUpdateId(_lastPlaybackRowUpdateIndex));
    }
    if (newIndex >= 0) {
      ids.add(feedPlaybackRowUpdateId(newIndex));
    }
    _lastPlaybackRowUpdateIndex = newIndex;
    if (ids.isNotEmpty) {
      update(ids.toList(growable: false));
    }
  }

  bool _isPlaybackTargetCurrent(int index) {
    if (index < 0 || index >= agendaList.length) return false;
    return VideoStateManager.instance.currentPlayingDocID ==
        agendaList[index].docID;
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
    if (_qaScrollStartedAt == null) {
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
