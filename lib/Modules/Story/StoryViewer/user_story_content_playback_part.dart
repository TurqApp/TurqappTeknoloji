// ignore_for_file: invalid_use_of_protected_member

part of 'user_story_content.dart';

extension UserStoryContentPlaybackPart on _UserStoryContentState {
  void _prefetchNextStoryVideoWithinCurrentUser() {
    try {
      final nextIndex = storyIndex + 1;
      if (nextIndex < 0 || nextIndex >= widget.user.stories.length) return;

      final nextStory = widget.user.stories[nextIndex];
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
    await _audioPlayer.stop(); // story değişince müzik durdur
    _musicStateSubscription?.cancel();

    if (storyIndex < widget.user.stories.length - 1) {
      final newIndex = storyIndex + 1;

      // Mevcut hikayeyi izlendi olarak işaretle (ara güncelleme)
      _markCurrentStoryAsSeen();

      setState(() {
        storyIndex = newIndex;
        progress = 0.0; // Progress'i sıfırla
      });

      _updateController(); // Controller'ı güncelle
      await Future.delayed(const Duration(
          milliseconds: 50)); // UI güncellemesi için kısa bekleme
      _startOrWait();
    } else {
      _timer?.cancel();
      widget.onUserStoryFinished?.call();
    }
  }

  void _prevStory() async {
    await _audioPlayer.stop(); // story değişince müzik durdur
    _musicStateSubscription?.cancel();

    if (storyIndex > 0) {
      final newIndex = storyIndex - 1;

      setState(() {
        storyIndex = newIndex;
        progress = 0.0; // Progress'i sıfırla
      });

      _updateController(); // Controller'ı güncelle
      await Future.delayed(const Duration(
          milliseconds: 50)); // UI güncellemesi için kısa bekleme
      _startOrWait();
    } else {
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

  // Page-level swipe handled in StoryViewer
}
