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
        _lastPlaybackCommandDocId != post.docID ||
            _lastPlaybackCommandAt == null ||
            now.difference(_lastPlaybackCommandAt!) >
                const Duration(milliseconds: 180);
    if (shouldIssueImmediateCommand) {
      if (manager.currentPlayingDocID == post.docID) {
        manager.reassertOnlyThis(post.docID);
      } else {
        manager.playOnlyThis(post.docID);
      }
      _lastPlaybackCommandDocId = post.docID;
      _lastPlaybackCommandAt = now;
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
      PrefetchScheduler.maybeFind()?.updateFeedQueue(docIds, safeCurrent);
    } catch (_) {}
  }

  int _resolveResumeIndex() {
    if (agendaList.isEmpty) return -1;

    final pendingDocIndex = _resolvePendingCenteredDocIndex();
    if (pendingDocIndex >= 0) return pendingDocIndex;

    int bestIndex = -1;
    double bestFraction = 0.0;
    _visibleFractions.forEach((idx, fraction) {
      if (idx < 0 || idx >= agendaList.length) return;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = idx;
      }
    });

    if (bestIndex >= 0) return bestIndex;
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < agendaList.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  int _resolveInitialCenteredIndex() {
    if (agendaList.isEmpty) return -1;
    final pendingDocIndex = _resolvePendingCenteredDocIndex();
    if (pendingDocIndex >= 0) {
      return pendingDocIndex;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length) {
      return lastCenteredIndex!;
    }
    final firstAutoplay =
        agendaList.indexWhere((post) => _canAutoplayVideoPost(post));
    if (firstAutoplay >= 0) {
      return firstAutoplay;
    }
    return 0;
  }

  void primeInitialCenteredPost() {
    final target = _resolveInitialCenteredIndex();
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
    int target = _resolveResumeIndex();
    if (target < 0 || target >= agendaList.length) {
      target = 0;
    }

    if (!_canAutoplayVideoPost(agendaList[target])) {
      final nextVideo =
          agendaList.indexWhere((p) => _canAutoplayVideoPost(p), target);
      if (nextVideo != -1) {
        target = nextVideo;
      } else {
        final anyVideo = agendaList.indexWhere((p) => _canAutoplayVideoPost(p));
        if (anyVideo != -1) target = anyVideo;
      }
    }

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

  int _resolvePendingCenteredDocIndex() {
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId == null || pendingDocId.isEmpty) return -1;
    return agendaList.indexWhere((post) => post.docID == pendingDocId);
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
      AdmobBannerWarmupService.ensure().warmForSurfaceEntry(
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
      fetchAgendaBigData();
    }

    final shouldShowFab = currentOffset <= 1000;
    if (showFAB.value != shouldShowFab) {
      showFAB.value = shouldShowFab;
    }

    _scrollIdleDebounce?.cancel();
    _scrollIdleDebounce = Timer(
      const Duration(milliseconds: 220),
      () {
        final centered = centeredIndex.value;
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
