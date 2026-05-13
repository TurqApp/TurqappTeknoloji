// ignore_for_file: invalid_use_of_protected_member

part of 'user_story_content.dart';

extension UserStoryContentPlaybackPart on _UserStoryContentState {
  static const int _storyPriorityBatchSize = 5;
  static const int _storyInitialVideoWindowSize = 5;
  static const int _storyInitialReadySegments = 1;
  static const int _storyActiveBatchReadySegments = 2;
  static const int _storyNextBatchPromotionTriggerOffset = 2;
  static const Duration _storyPriorityPlanTick = Duration(milliseconds: 900);

  bool _storyHasPlayableVideo(StoryModel story) {
    for (final element in story.elements) {
      if (element.type == StoryElementType.video &&
          element.content.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  StoryElement? _firstPlayableVideoElement(StoryModel story) {
    for (final element in story.elements) {
      if (element.type == StoryElementType.video &&
          element.content.trim().isNotEmpty) {
        return element;
      }
    }
    return null;
  }

  String _storyMediaDocId(StoryModel story) {
    final video = _firstPlayableVideoElement(story);
    return hlsDocIdFromUrlOrPath(video?.content ?? '') ?? story.id.trim();
  }

  Future<void> _stopStoryVideoForTransition(
    StoryModel story, {
    required String reason,
  }) async {
    final storyId = story.id.trim();
    final mediaDocId = _storyMediaDocId(story).trim();
    if (storyId.isEmpty && mediaDocId.isEmpty) return;
    debugPrint(
      '[StoryPlaybackStop] action=transition_start reason=$reason '
      'story=${storyId.isEmpty ? '-' : storyId} '
      'mediaDoc=${mediaDocId.isEmpty ? '-' : mediaDocId}',
    );

    var stoppedMountedVideo = false;
    try {
      if (storyId.isNotEmpty) {
        stoppedMountedVideo =
            await StoryVideoPlaybackRegistry.stop(storyId, reason: reason);
      }
      if (!stoppedMountedVideo &&
          mediaDocId.isNotEmpty &&
          mediaDocId != storyId) {
        await StoryVideoPlaybackRegistry.stop(mediaDocId, reason: reason);
      }
    } catch (_) {}

    try {
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch != null) {
        if (storyId.isNotEmpty) {
          prefetch.abortShortSwipeBoundaryDoc(storyId, reason: reason);
        }
        if (mediaDocId.isNotEmpty && mediaDocId != storyId) {
          prefetch.abortShortSwipeBoundaryDoc(mediaDocId, reason: reason);
        }
      }
    } catch (_) {}

    try {
      if (storyId.isNotEmpty) {
        releaseExternalOnDemandFetchForDoc(storyId);
      }
      if (mediaDocId.isNotEmpty && mediaDocId != storyId) {
        releaseExternalOnDemandFetchForDoc(mediaDocId);
      }
    } catch (_) {}

    debugPrint(
      '[StoryPlaybackStop] action=transition_done reason=$reason '
      'story=${storyId.isEmpty ? '-' : storyId} '
      'mediaDoc=${mediaDocId.isEmpty ? '-' : mediaDocId}',
    );
  }

  List<StoryModel> _videoStoriesForCurrentUser() {
    return widget.user.stories
        .where(_storyHasPlayableVideo)
        .toList(growable: false);
  }

  int _resolveCurrentVideoStoryOrder(List<StoryModel> videoStories) {
    if (videoStories.isEmpty) return 0;
    for (var order = 0; order < videoStories.length; order++) {
      final story = videoStories[order];
      final sourceIndex =
          widget.user.stories.indexWhere((s) => s.id == story.id);
      if (sourceIndex >= storyIndex) {
        return order;
      }
    }
    return videoStories.length - 1;
  }

  void _cacheStoryVideoIfNeeded(StoryModel story) {
    final cacheManager = maybeFindSegmentCacheManager();
    if (cacheManager == null || !cacheManager.isReady) return;
    final video = _firstPlayableVideoElement(story);
    if (video == null) return;
    final storyId = story.id.trim();
    final playbackUrl = canonicalizeHlsCdnUrl(video.content);
    if (storyId.isEmpty || hlsRelativePathFromUrlOrPath(playbackUrl) == null) {
      return;
    }
    cacheManager.cacheHlsEntry(storyId, playbackUrl);
  }

  String _firstStoryVisualCoverUrl(StoryModel story) {
    for (final element in story.elements) {
      if (element.type == StoryElementType.video) {
        final posterUrl = element.posterUrl.trim();
        if (posterUrl.isNotEmpty) return posterUrl;
      } else if (element.type == StoryElementType.image ||
          element.type == StoryElementType.gif) {
        final imageUrl = element.content.trim();
        if (imageUrl.isNotEmpty) return imageUrl;
      }
    }
    return '';
  }

  void _precacheStoryVisualCover(StoryModel story, {required String reason}) {
    final storyId = story.id.trim();
    final imageUrl = _firstStoryVisualCoverUrl(story);
    if (storyId.isEmpty || imageUrl.isEmpty) return;
    debugPrint(
      '[StoryVisualCover] action=precache_queued reason=$reason '
      'story=$storyId',
    );
    unawaited(
      TurqImageCacheManager.instance.getSingleFile(imageUrl).then((file) {
        if (!mounted) return Future<void>.value();
        return precacheImage(FileImage(File(file.path)), context);
      }).catchError((_) {}),
    );
  }

  void _precacheStoryVisualCoversFromIndex({
    required int startIndex,
    required int count,
    required String reason,
  }) {
    if (widget.user.stories.isEmpty || count <= 0) return;
    final safeStart = startIndex.clamp(0, widget.user.stories.length - 1);
    final endExclusive =
        (safeStart + count).clamp(0, widget.user.stories.length);
    for (var index = safeStart; index < endExclusive; index++) {
      _precacheStoryVisualCover(
        widget.user.stories[index],
        reason: '$reason:index_$index',
      );
    }
  }

  void _updateStoryPrefetchPriorityContext([List<StoryModel>? seededStories]) {
    try {
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch == null) return;
      final videoStories = seededStories ?? _videoStoriesForCurrentUser();
      if (videoStories.isEmpty) return;
      final videoStoryDocIds = <String>[];
      for (final story in videoStories) {
        final storyId = story.id.trim();
        if (storyId.isEmpty) continue;
        videoStoryDocIds.add(storyId);
      }
      if (videoStoryDocIds.isEmpty) return;
      final currentVideoOrder = _resolveCurrentVideoStoryOrder(videoStories)
          .clamp(0, videoStoryDocIds.length - 1);
      final safeCurrent =
          currentVideoOrder.clamp(0, videoStoryDocIds.length - 1);
      prefetch.updatePriorityWindowContext(videoStoryDocIds, safeCurrent);
    } catch (_) {}
  }

  void _scheduleStoryVideoWarmupFromOrder({
    required int startOrder,
    required int readySegments,
    int? windowCount,
    String reason = 'story_priority',
  }) {
    final videoStories = _videoStoriesForCurrentUser();
    if (videoStories.isEmpty) return;
    if (startOrder < 0 || startOrder >= videoStories.length) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;

    _updateStoryPrefetchPriorityContext(videoStories);
    final endExclusive = (startOrder + (windowCount ?? videoStories.length))
        .clamp(0, videoStories.length);
    if (endExclusive <= startOrder) return;
    debugPrint(
      '[StoryUserWarm] action=schedule reason=$reason '
      'startOrder=$startOrder endOrder=${endExclusive - 1} '
      'readySegments=$readySegments count=${endExclusive - startOrder}',
    );
    for (var order = startOrder; order < endExclusive; order++) {
      final story = videoStories[order];
      final storyId = story.id.trim();
      if (storyId.isEmpty) continue;
      _cacheStoryVideoIfNeeded(story);
      try {
        prefetch.boostDoc(
          storyId,
          readySegments: readySegments,
        );
      } catch (_) {}
    }
  }

  bool _allStoryVideoSegmentsReady(int segmentCount) {
    if (segmentCount <= 0) return true;
    final cacheManager = SegmentCacheManager.maybeFind();
    if (cacheManager == null || !cacheManager.isReady) return false;
    for (final story in _videoStoriesForCurrentUser()) {
      final storyId = story.id.trim();
      if (storyId.isEmpty) continue;
      final entry = cacheManager.getEntry(storyId);
      if ((entry?.cachedSegmentCount ?? 0) < segmentCount) {
        return false;
      }
    }
    return true;
  }

  void _resetStorySegmentPriorityPlan() {
    _promotedStorySecondSegmentBatchStarts.clear();
  }

  void _scheduleStorySegmentPriorityPlanForCurrentPosition() {
    _precacheStoryVisualCoversFromIndex(
      startIndex: storyIndex,
      count: _storyInitialVideoWindowSize,
      reason: 'entry_visual_window',
    );

    final videoStories = _videoStoriesForCurrentUser();
    if (videoStories.isEmpty) return;
    _resetStorySegmentPriorityPlan();
    _updateStoryPrefetchPriorityContext(videoStories);

    final currentOrder = _resolveCurrentVideoStoryOrder(videoStories);
    _scheduleStoryVideoWarmupFromOrder(
      startOrder: 0,
      readySegments: _storyInitialReadySegments,
      windowCount: _storyInitialVideoWindowSize,
      reason: 'entry_first_five',
    );

    final currentBatchStart =
        (currentOrder ~/ _storyPriorityBatchSize) * _storyPriorityBatchSize;
    final currentBatchCount = (videoStories.length - currentBatchStart)
        .clamp(0, _storyPriorityBatchSize);
    if (currentBatchCount <= 0) return;

    _scheduleStoryVideoWarmupFromOrder(
      startOrder: currentBatchStart,
      readySegments: _storyActiveBatchReadySegments,
      windowCount: currentBatchCount,
      reason: 'active_batch',
    );
    _promotedStorySecondSegmentBatchStarts.add(currentBatchStart);

    if (currentBatchStart > 0) {
      _scheduleStoryVideoWarmupFromOrder(
        startOrder: 0,
        readySegments: _storyInitialReadySegments,
        windowCount: currentBatchStart,
        reason: 'leading_context',
      );
    }

    final trailingStart = currentBatchStart + currentBatchCount;
    if (trailingStart < videoStories.length) {
      _scheduleStoryVideoWarmupFromOrder(
        startOrder: trailingStart,
        readySegments: _storyInitialReadySegments,
        windowCount: videoStories.length - trailingStart,
        reason: 'trailing_context',
      );
    }
  }

  void _promoteNextStorySegmentBatchIfNeeded() {
    final videoStories = _videoStoriesForCurrentUser();
    if (videoStories.isEmpty) return;
    final currentOrder = _resolveCurrentVideoStoryOrder(videoStories);
    final currentBatchStart =
        (currentOrder ~/ _storyPriorityBatchSize) * _storyPriorityBatchSize;
    final promotionThreshold =
        currentBatchStart + _storyNextBatchPromotionTriggerOffset;
    if (currentOrder < promotionThreshold) return;

    final nextBatchStart = currentBatchStart + _storyPriorityBatchSize;
    if (nextBatchStart >= videoStories.length) return;
    if (!_promotedStorySecondSegmentBatchStarts.add(nextBatchStart)) return;

    final nextBatchCount = (videoStories.length - nextBatchStart)
        .clamp(0, _storyPriorityBatchSize);
    if (nextBatchCount <= 0) return;
    _scheduleStoryVideoWarmupFromOrder(
      startOrder: nextBatchStart,
      readySegments: _storyActiveBatchReadySegments,
      windowCount: nextBatchCount,
      reason: 'next_batch_promote',
    );
  }

  void _promoteStorySecondSegmentSweepIfNeeded() {
    final videoStories = _videoStoriesForCurrentUser();
    if (videoStories.isEmpty) return;
    if (!_allStoryVideoSegmentsReady(1)) return;
    final cacheManager = SegmentCacheManager.maybeFind();
    if (cacheManager == null || !cacheManager.isReady) return;

    for (var batchStart = 0;
        batchStart < videoStories.length;
        batchStart += _storyPriorityBatchSize) {
      final batchCount =
          (videoStories.length - batchStart).clamp(0, _storyPriorityBatchSize);
      if (batchCount <= 0) return;

      var needsSecondSegment = false;
      for (var order = batchStart; order < batchStart + batchCount; order++) {
        final storyId = videoStories[order].id.trim();
        if (storyId.isEmpty) continue;
        final entry = cacheManager.getEntry(storyId);
        if ((entry?.cachedSegmentCount ?? 0) < 2) {
          needsSecondSegment = true;
          break;
        }
      }

      if (!needsSecondSegment) {
        continue;
      }

      if (_promotedStorySecondSegmentBatchStarts.add(batchStart)) {
        _scheduleStoryVideoWarmupFromOrder(
          startOrder: batchStart,
          readySegments: _storyActiveBatchReadySegments,
          windowCount: batchCount,
          reason: 'second_segment_sweep',
        );
      }
      return;
    }
  }

  void _startStoryPriorityPlanTicker() {
    _storyPriorityPlanTimer?.cancel();
    _storyPriorityPlanTimer = Timer.periodic(_storyPriorityPlanTick, (_) {
      _promoteStorySecondSegmentSweepIfNeeded();
    });
  }

  void _primeStoryTransitionCover(int index, {required String reason}) {
    if (index < 0 || index >= widget.user.stories.length) {
      _storyTransitionCoverStoryId = null;
      return;
    }
    final story = widget.user.stories[index];
    _precacheStoryVisualCover(story, reason: 'prime_$reason');
    var hasCover = false;
    for (final element in story.elements) {
      if (element.type == StoryElementType.video) {
        if (element.posterUrl.trim().isNotEmpty) {
          hasCover = true;
          break;
        }
      } else if (element.type == StoryElementType.image ||
          element.type == StoryElementType.gif) {
        if (element.content.trim().isNotEmpty) {
          hasCover = true;
          break;
        }
      }
    }
    _storyTransitionCoverStoryId = hasCover ? story.id : null;
    debugPrint(
      '[StoryVisualCover] action=prime reason=$reason index=$index '
      'story=${story.id} hasCover=$hasCover',
    );
  }

  void _clearStoryTransitionCover(String storyId, {required String reason}) {
    if (_storyTransitionCoverStoryId != storyId) return;
    setState(() {
      _storyTransitionCoverStoryId = null;
    });
    debugPrint(
      '[StoryVisualCover] action=clear reason=$reason story=$storyId',
    );
  }

  void _prefetchNextStoryVideoWithinCurrentUser() {
    try {
      _updateStoryPrefetchPriorityContext();
      final nextIndex = storyIndex + 1;
      if (nextIndex < 0 || nextIndex >= widget.user.stories.length) return;

      final nextStory = widget.user.stories[nextIndex];
      _precacheStoryVisualCover(nextStory, reason: 'next_story');
      StoryElement? nextVideo;
      for (final element in nextStory.elements) {
        if (element.type == StoryElementType.video &&
            element.content.trim().isNotEmpty) {
          nextVideo = element;
          break;
        }
      }
      if (nextVideo == null) return;

      final cacheManager = maybeFindSegmentCacheManager();
      final prefetch = maybeFindPrefetchScheduler();
      if (cacheManager == null || !cacheManager.isReady || prefetch == null) {
        return;
      }

      final storyId = nextStory.id.trim();
      final playbackUrl = canonicalizeHlsCdnUrl(nextVideo.content);
      if (storyId.isEmpty ||
          hlsRelativePathFromUrlOrPath(playbackUrl) == null) {
        return;
      }

      cacheManager.cacheHlsEntry(storyId, playbackUrl);
      prefetch.boostDoc(
        storyId,
        readySegments: SegmentCacheRuntimeService.globalReadySegmentCount,
      );
    } catch (_) {}
  }

  Future<void> _pauseStoryAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (_) {}
  }

  Future<void> _resumeStoryAudio() async {
    try {
      await AudioFocusCoordinator.instance.requestAudioPlayerPlay(_audioPlayer);
      await _audioPlayer.setVolume(1);
      await _audioPlayer.resume();
    } catch (_) {}
  }

  Future<void> _playStoryAudioSource(Source source) async {
    await AudioFocusCoordinator.instance.requestAudioPlayerPlay(_audioPlayer);
    await _audioPlayer.setVolume(1);
    await _audioPlayer.play(source);
  }

  Future<void> _pauseCurrentStoryPlayback() async {
    _timer?.cancel();
    _musicStartFallbackTimer?.cancel();
    await _pauseStoryAudio();
  }

  Future<void> _resumeCurrentStoryPlayback() async {
    if (!mounted ||
        _isHoldPaused ||
        storyIndex < 0 ||
        storyIndex >= widget.user.stories.length) {
      return;
    }

    _timer?.cancel();
    _musicStartFallbackTimer?.cancel();

    final currentStory = widget.user.stories[storyIndex];
    final hasMusic = currentStory.musicUrl.trim().isNotEmpty;
    final hasVideo = currentStory.elements
        .any((element) => element.type == StoryElementType.video);

    if (hasMusic) {
      if (!_waitingForMusic) {
        setState(() {
          _waitingForMusic = true;
        });
      }

      _musicStartFallbackTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || _isHoldPaused || !_waitingForMusic) return;
        setState(() {
          _waitingForMusic = false;
        });
        _startProgress();
      });

      await _resumeStoryAudio();
      return;
    }

    if (hasVideo && _waitingForVideo) return;
    _startProgress();
  }

  Future<void> _startOrWait() async {
    _timer?.cancel();
    _musicStateSubscription?.cancel();

    // İndex doğrulaması
    if (storyIndex >= widget.user.stories.length || storyIndex < 0) {
      debugPrint("Invalid story index");
      return;
    }

    setState(() {
      progress = 0.0;
      _waitingForMusic = false;
    });

    final currentStory = widget.user.stories[storyIndex];
    _updateStoryPrefetchPriorityContext();
    _scheduleStorySegmentPriorityPlanForCurrentPosition();
    _promoteNextStorySegmentBatchIfNeeded();
    unawaited(Future<void>.microtask(_prefetchNextStoryVideoWithinCurrentUser));

    controller.getLikes(currentStory.id);
    controller.setSeen(currentStory.id);
    final videoElement = currentStory.elements
        .firstWhereOrNull((e) => e.type == StoryElementType.video);
    // --- MÜZİK VARSA ---
    if (currentStory.musicUrl != "" && currentStory.musicUrl.isNotEmpty) {
      progressMaxDuration = const Duration(seconds: 30); // 30 sn!
      if (_currentMusicUrl != currentStory.musicUrl) {
        _currentMusicUrl = currentStory.musicUrl;

        // Önce stop (varsa)
        await _audioPlayer.stop();

        setState(() {
          _waitingForMusic = true;
        });
        // Güvenli fallback: 2 saniye içinde playing olmazsa ilerlemeyi başlat
        _musicStartFallbackTimer?.cancel();
        _musicStartFallbackTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _waitingForMusic) {
            _waitingForMusic = false;
            _startProgress();
          }
        });

        // Dinleyici kur
        _musicStateSubscription =
            _audioPlayer.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.playing && _waitingForMusic) {
            setState(() {
              _waitingForMusic = false;
            });
            _startProgress();
          }
        });

        // Play müzik ve state değişimini bekle
        try {
          final playablePath = await StoryMusicLibraryService.instance
              .resolvePlayablePath(_currentMusicUrl!);
          if (playablePath.isNotEmpty) {
            await _playStoryAudioSource(DeviceFileSource(playablePath));
          } else {
            await _playStoryAudioSource(UrlSource(_currentMusicUrl!));
          }
          unawaited(StoryMusicLibraryService.instance.warmTrackFromStory(
            audioUrl: currentStory.musicUrl,
            coverUrl: currentStory.musicCoverUrl,
          ));
        } catch (e) {
          debugPrint("Story music load error: $e");
          _waitingForMusic = false;
          _startProgress(); // fallback
        }
      } else {
        // Aynı müzikse resume et ve bekle
        await _resumeStoryAudio();
        setState(() {
          _waitingForMusic = true;
        });
        _musicStateSubscription =
            _audioPlayer.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.playing && _waitingForMusic) {
            setState(() {
              _waitingForMusic = false;
            });
            _startProgress();
          }
        });
        // Güvenli fallback: 2 saniye içinde playing olmazsa ilerlemeyi başlat
        _musicStartFallbackTimer?.cancel();
        _musicStartFallbackTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _waitingForMusic) {
            _waitingForMusic = false;
            _startProgress();
          }
        });
      }
      // NOT: progress burada başlamaz, state playing'e geçince başlayacak!
    } else {
      // --- MÜZİK YOKSA ---
      progressMaxDuration = const Duration(seconds: 15);
      _currentMusicUrl = null;
      await _audioPlayer.stop();
      if (videoElement != null) {
        setState(() {
          _waitingForVideo = true;
        });
      } else {
        setState(() {
          _waitingForVideo = false;
        });
        _startProgress();
      }
    }
  }

  void _startProgress() {
    _timer?.cancel();
    const updateInterval = Duration(milliseconds: 50);
    final increment =
        updateInterval.inMilliseconds / progressMaxDuration.inMilliseconds;

    _timer = Timer.periodic(updateInterval, (timer) {
      if (mounted) {
        setState(() {
          progress += increment;
          if (progress >= 1.0) {
            progress = 1.0;
            _timer?.cancel();
            _nextStory(auto: true);
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _nextStory({bool auto = false}) async {
    final previousStory =
        storyIndex >= 0 && storyIndex < widget.user.stories.length
            ? widget.user.stories[storyIndex]
            : null;
    await _audioPlayer.stop(); // story değişince müzik durdur
    _musicStateSubscription?.cancel();

    if (storyIndex < widget.user.stories.length - 1) {
      final newIndex = storyIndex + 1;

      // Mevcut hikayeyi izlendi olarak işaretle (ara güncelleme)
      _markCurrentStoryAsSeen();

      setState(() {
        storyIndex = newIndex;
        progress = 0.0; // Progress'i sıfırla
        _primeStoryTransitionCover(newIndex, reason: 'next_story');
      });

      _updateController(); // Controller'ı güncelle
      if (previousStory != null) {
        unawaited(_stopStoryVideoForTransition(
          previousStory,
          reason: auto ? 'story_auto_next' : 'story_tap_next',
        ));
      }
      _promoteNextStorySegmentBatchIfNeeded();
      _startOrWait();
    } else {
      if (previousStory != null) {
        await _stopStoryVideoForTransition(
          previousStory,
          reason: auto ? 'story_auto_finish' : 'story_tap_finish',
        );
      }
      _timer?.cancel();
      widget.onUserStoryFinished?.call();
    }
  }

  void _prevStory() async {
    final previousStory =
        storyIndex >= 0 && storyIndex < widget.user.stories.length
            ? widget.user.stories[storyIndex]
            : null;
    await _audioPlayer.stop(); // story değişince müzik durdur
    _musicStateSubscription?.cancel();

    if (storyIndex > 0) {
      final newIndex = storyIndex - 1;

      setState(() {
        storyIndex = newIndex;
        progress = 0.0; // Progress'i sıfırla
        _primeStoryTransitionCover(newIndex, reason: 'prev_story');
      });

      _updateController(); // Controller'ı güncelle
      if (previousStory != null) {
        unawaited(_stopStoryVideoForTransition(
          previousStory,
          reason: 'story_tap_prev',
        ));
      }
      _promoteNextStorySegmentBatchIfNeeded();
      _startOrWait();
    } else {
      if (previousStory != null) {
        await _stopStoryVideoForTransition(
          previousStory,
          reason: 'story_prev_user',
        );
      }
      widget.onPrevUserRequested?.call();
    }
  }

  /// Mevcut hikayeyi optimize edilmiş sistemle işaretle
  void _markCurrentStoryAsSeen() {
    if (storyIndex < widget.user.stories.length) {
      final currentStory = widget.user.stories[storyIndex];
      final userID = widget.user.userID;

      // Optimize edilmiş debounced marking (500ms batch)
      ensureStoryInteractionOptimizer().markStoryViewed(userID, currentStory.id,
          currentStory.createdAt.millisecondsSinceEpoch);
    }
  }

  // Parent (StoryViewer) upward swipe triggers this to open comments
  Future<void> openCommentsFromParent() async {
    if (!mounted) return;
    final currentStory = widget.user.stories[storyIndex];
    try {
      FocusScope.of(context).unfocus();
      await _pauseCurrentStoryPlayback();
      await controller.showPostCommentsBottomSheet(
        currentStory.id,
        widget.user.nickname,
        widget.user.userID == _currentUid,
        onClosed: (v) {
          if (!mounted) return;
          unawaited(_resumeCurrentStoryPlayback());
        },
      );
    } catch (_) {}
  }

  Future<void> stopPlaybackFromParent({
    String reason = 'story_page_transition',
  }) async {
    if (!mounted) return;
    _timer?.cancel();
    _musicStartFallbackTimer?.cancel();
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _musicStateSubscription?.cancel();
    if (storyIndex < 0 || storyIndex >= widget.user.stories.length) {
      return;
    }
    await _stopStoryVideoForTransition(
      widget.user.stories[storyIndex],
      reason: reason,
    );
  }

  // Page-level swipe handled in StoryViewer
}
