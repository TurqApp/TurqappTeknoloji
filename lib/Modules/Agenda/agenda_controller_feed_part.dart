part of 'agenda_controller.dart';

extension AgendaControllerFeedPart on AgendaController {
  void _bindCenteredIndexListener() {
    ever<int>(centeredIndex, (newIndex) {
      final videoManager = VideoStateManager.instance;

      if (newIndex == -1) {
        videoManager.pauseAllVideos();
        return;
      }

      if (newIndex >= 0 && newIndex < agendaList.length) {
        final centeredPost = agendaList[newIndex];
        if (_canAutoplayVideoPost(centeredPost)) {
          videoManager.playOnlyThis(centeredPost.docID);
        } else {
          videoManager.pauseAllVideos();
        }
      }

      _scheduleFeedPrefetch();
    });
  }

  void _scheduleFeedPrefetch() {
    _feedPrefetchDebounce?.cancel();
    _feedPrefetchDebounce = Timer(const Duration(milliseconds: 500), () {
      _updateFeedPrefetchQueue();
    });
  }

  void _updateFeedPrefetchQueue() {
    if (agendaList.isEmpty) return;

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
      Get.find<PrefetchScheduler>().updateFeedQueue(docIds, safeCurrent);
    } catch (_) {}
  }

  int _resolveResumeIndex() {
    if (agendaList.isEmpty) return -1;

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
    centeredIndex.value = target;
    lastCenteredIndex = target;
  }

  void resumeFeedPlayback() {
    if (agendaList.isEmpty) return;

    pauseAll.value = false;
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

    final targetPost = agendaList[target];
    if (!_canAutoplayVideoPost(targetPost)) return;

    final manager = VideoStateManager.instance;
    manager.playOnlyThis(targetPost.docID);

    Future.delayed(const Duration(milliseconds: 220), () {
      if (centeredIndex.value != target) return;
      manager.playOnlyThis(targetPost.docID);
    });
  }

  void _prefetchUpcomingImages() {
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final end = (current + 6).clamp(0, agendaList.length);
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

  void ensureFeedCacheWarm() {
    _scheduleFeedPrefetch();
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

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      fetchAgendaBigData();
    }

    final shouldShowFab = currentOffset <= 1000;
    if (showFAB.value != shouldShowFab) {
      showFAB.value = shouldShowFab;
    }
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
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
