import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/posts_model.dart';
import '../../../main.dart';
import '../../../hls_player/hls_video_adapter.dart';
import '../../../Core/Services/SegmentCache/cache_manager.dart';
import '../../../Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import '../../../Core/Services/qa_lab_bridge.dart';
import '../../../Core/Services/video_state_manager.dart';
import '../../../Core/Services/video_telemetry_service.dart';
import '../../../Core/Services/playback_handle.dart';
import '../../../Core/Services/global_video_adapter_pool.dart';
import '../../../Ads/admob_kare.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Explore/explore_controller.dart';
import '../../NavBar/nav_bar_controller.dart';
import '../../Profile/MyProfile/profile_controller.dart';
import '../../Profile/Archives/archives_controller.dart';
import '../../Profile/LikedPosts/liked_posts_controller.dart';
import '../../Profile/Settings/settings_controller.dart';
import '../../SocialProfile/social_profile_controller.dart';
import '../../Agenda/TopTags/top_tags_contoller.dart';
import '../../Agenda/TagPosts/tag_posts_controller.dart';
import '../../Agenda/FloodListing/flood_listing_controller.dart';
import 'post_content_controller.dart';

part 'post_content_base_lifecycle_part.dart';

/// Base widget/state that encapsulates the shared behaviour between
/// Modern (AgendaContent) and Classic content cards.
abstract class PostContentBase extends StatefulWidget {
  const PostContentBase({
    super.key,
    required this.model,
    required this.isPreview,
    required this.shouldPlay,
    this.instanceTag,
    required this.isReshared,
    required this.reshareUserID,
    required this.showComments,
    required this.showArchivePost,
  });

  final PostsModel model;
  final bool isPreview;
  final bool shouldPlay;
  final String? instanceTag;
  final bool isReshared;
  final String? reshareUserID;
  final bool showComments;
  final bool showArchivePost;

  /// Factory for the specific controller implementation.
  PostContentController createController();
}

mixin PostContentBaseState<T extends PostContentBase> on State<T>
    implements RouteAware {
  late final AgendaController agendaController = _resolveAgendaController();
  late final GlobalVideoAdapterPool adapterPool =
      GlobalVideoAdapterPool.ensure();
  final videoStateManager = VideoStateManager.instance;

  late final PostContentController controller;
  HLSVideoAdapter? _videoAdapter;
  bool _hasAutoPlayed = false;
  bool _skipNextPause = false;
  bool _blockPause = false;
  bool _replayOverlayLatched = false;
  bool _replayAdPrewarmed = false;
  bool _replayAdVisible = false;
  bool _replayButtonVisible = false;
  bool _replayAdImpressionReceived = false;
  Timer? _replayAdHideTimer;
  Worker? _muteWorker;
  Worker? _pauseAllWorker;
  Worker? _playbackSuspendedWorker;
  Worker? _navSelectionWorker;
  Timer? _lazyInitTimer;
  Timer? _playbackRecoveryTimer;
  bool _playbackIntentTracked = false;

  /// Video state'i sadece süre/replay göstergesini güncellemek için.
  /// setState yerine ValueNotifier kullanarak tüm post'u rebuild etmekten kaçınıyoruz.
  final ValueNotifier<HLSVideoValue> videoValueNotifier =
      ValueNotifier(const HLSVideoValue());
  static const Duration _stableFramePositionThreshold =
      Duration(milliseconds: 180);

  AgendaController _resolveAgendaController() {
    return AgendaController.ensure();
  }

  /// videoController benzeri erişim — mevcut widget'lar uyumlu çalışır
  HLSVideoAdapter? get videoController => _videoAdapter;

  bool get isVideoFromCache {
    if (!widget.model.hasPlayableVideo) return false;
    try {
      final entry =
          SegmentCacheManager.maybeFind()?.getEntry(widget.model.docID);
      if (entry == null) return false;
      return entry.cachedSegmentCount > 0;
    } catch (_) {
      return false;
    }
  }

  /// 🎯 INSTAGRAM STYLE: Buffer BEKLEMEDEN direkt oynat
  bool get enableBufferedAutoplay => false;

  double get bufferedAutoplayThreshold => 0.10;

  /// Unique tag for GetX controller retrieval.
  String get controllerTag => widget.instanceTag ?? widget.model.docID;

  /// Playback handle identity must be unique per mounted video surface.
  /// Otherwise feed card and SinglePost can fight over the same player slot.
  String get playbackHandleKey => widget.instanceTag ?? widget.model.docID;

  bool get isStandalonePostInstance =>
      (widget.instanceTag ?? '').startsWith('single_');

  String get _surfaceInstanceTag => widget.instanceTag ?? '';

  bool get _isProfileSurfaceInstance =>
      _surfaceInstanceTag.startsWith('profile_');

  bool get _isProfileFamilySurfaceInstance =>
      _surfaceInstanceTag.startsWith('profile_') ||
      _surfaceInstanceTag.startsWith('archives_') ||
      _surfaceInstanceTag.startsWith('liked_post_') ||
      _surfaceInstanceTag.startsWith('social_');

  bool get _isPrimaryFeedSurfaceInstance =>
      !isStandalonePostInstance && _surfaceInstanceTag.isEmpty;

  bool get _useLegacyIosFeedBehavior =>
      defaultTargetPlatform == TargetPlatform.iOS &&
      !isStandalonePostInstance &&
      !_isPrimaryFeedSurfaceInstance &&
      !_isProfileFamilySurfaceInstance;

  bool get _isReplayOverlayEnabled =>
      !isStandalonePostInstance && !_useLegacyIosFeedBehavior;

  bool get _isSurfacePlaybackAllowed {
    if (isStandalonePostInstance) return true;
    if (!_isProfileSurfaceInstance) {
      return agendaController.canClaimPlaybackNow;
    }
    final nav = NavBarController.maybeFind();
    final settings = SettingsController.maybeFind();
    final hasEducation = settings?.educationScreenIsOn.value ?? false;
    final profileIndex = hasEducation ? 4 : 3;
    return nav?.selectedIndex.value == profileIndex;
  }

  bool get shouldLoopVideo =>
      isStandalonePostInstance || _useLegacyIosFeedBehavior;

  String get _qaSurfaceName {
    if (isStandalonePostInstance) return 'feed';
    if (_isProfileFamilySurfaceInstance) return 'profile';
    return 'feed';
  }

  String get _qaScrollToken {
    if (_qaSurfaceName != 'feed') return '';
    return agendaController.latestQAScrollToken;
  }

  void _recordPlaybackDispatch(
    String stage, {
    String source = '',
    bool dispatchIssued = true,
    String skipReason = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    recordQALabPlaybackDispatch(
      surface: _qaSurfaceName,
      stage: stage,
      metadata: <String, dynamic>{
        'docId': widget.model.docID,
        'instanceTag': widget.instanceTag ?? '',
        'shouldPlay': widget.shouldPlay,
        'isStandalone': isStandalonePostInstance,
        'isProfileSurface': _isProfileSurfaceInstance,
        'isProfileFamilySurface': _isProfileFamilySurfaceInstance,
        'adapterInitialized': _videoAdapter?.value.isInitialized ?? false,
        'adapterPlaying': _videoAdapter?.value.isPlaying ?? false,
        'dispatchIssued': dispatchIssued,
        'dispatchSource': source,
        'callerSignature': source,
        'skipReason': skipReason,
        'scrollToken': _qaScrollToken,
        'currentPlayingDocId': videoStateManager.currentPlayingDocID ?? '',
        ...metadata,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _handleLifecycleInit();
  }

  void _initVideoController() {
    if (_videoAdapter != null) return;
    _videoAdapter = adapterPool.acquire(
      cacheKey: playbackHandleKey,
      url: widget.model.playbackUrl,
      // iOS feed, eski daha akıcı davranışı korusun; Android ise manual
      // dispatch ile çift-play dalgasından kaçınsın.
      autoPlay: _useLegacyIosFeedBehavior ? widget.shouldPlay : false,
      loop: shouldLoopVideo,
    );
    _videoAdapter!.hlsController.setTelemetryVideoId(widget.model.docID);

    videoStateManager.registerPlaybackHandle(
      playbackHandleKey,
      HLSAdapterPlaybackHandle(_videoAdapter!),
    );
    if (isStandalonePostInstance) {
      videoStateManager.enterExclusiveMode(playbackHandleKey);
    }

    _videoAdapter!.addListener(_onVideoUpdate);

    if (!isStandalonePostInstance) {
      _muteWorker = ever<bool>(agendaController.isMuted, (muted) {
        _videoAdapter?.setVolume(muted ? 0.0 : 1.0);
        _syncRuntimeHints(isAudible: !muted);
      });
    } else {
      _videoAdapter?.setVolume(1.0);
      _syncRuntimeHints(isAudible: true);
    }

    if (!isStandalonePostInstance) {
      _pauseAllWorker = ever(agendaController.pauseAll, (value) {
        if (value == true) {
          _safePauseVideo();
        } else {
          _resumePlaybackIfEligible(source: 'pause_all_released');
        }
      });

      _playbackSuspendedWorker = ever<bool>(
        agendaController.playbackSuspended,
        (suspended) {
          if (suspended || !_isSurfacePlaybackAllowed) {
            _safePauseVideo();
          } else {
            _resumePlaybackIfEligible(source: 'playback_suspension_released');
          }
        },
      );

      final nav = NavBarController.maybeFind();
      if (nav != null) {
        _navSelectionWorker = ever<int>(nav.selectedIndex, (_) {
          if (!_isSurfacePlaybackAllowed) {
            _safePauseVideo();
          } else {
            _resumePlaybackIfEligible(source: 'nav_selection_changed');
          }
        });
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDidChangeDependencies();
  }

  @override
  void dispose() {
    _handleLifecycleDispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleDidUpdateWidget(oldWidget);
  }

  @override
  void didPushNext() => _handleDidPushNext();

  @override
  void didPopNext() => _handleDidPopNext();

  @override
  void didPush() {
    _resumePlaybackIfEligible(source: 'route_did_push');
  }

  @override
  void didPop() {}

  void _onVideoUpdate() => _handleVideoUpdate();

  bool _hasStableVideoFrame(HLSVideoValue value) {
    return value.hasRenderedFirstFrame &&
        !value.isCompleted &&
        (value.isPlaying || value.position > _stableFramePositionThreshold);
  }

  int _remainingSecondsBucket(HLSVideoValue value) {
    if (value.duration <= Duration.zero) return -1;
    final remaining = value.duration - value.position;
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    return safeRemaining.inSeconds;
  }

  bool _shouldSyncVideoNotifier(HLSVideoValue next) {
    final previous = videoValueNotifier.value;
    if (previous.isInitialized != next.isInitialized ||
        previous.isPlaying != next.isPlaying ||
        previous.isBuffering != next.isBuffering ||
        previous.isCompleted != next.isCompleted ||
        previous.hasRenderedFirstFrame != next.hasRenderedFirstFrame) {
      return true;
    }
    if (_hasStableVideoFrame(previous) != _hasStableVideoFrame(next)) {
      return true;
    }
    return _remainingSecondsBucket(previous) != _remainingSecondsBucket(next);
  }

  void _markPostContentDirty() {
    if (!mounted) return;
    setState(() {});
  }

  void _safePauseVideo() {
    final v = _videoAdapter;
    if (v != null) {
      v.pause();
      _hasAutoPlayed = false;
      _playbackIntentTracked = false;
      _syncRuntimeHints(hasStableFocus: false);
    }
  }

  void pauseVideo() => _safePauseVideo();

  void _applyPlaybackVolume() {
    _videoAdapter?.setVolume(
      isStandalonePostInstance
          ? 1.0
          : (agendaController.isMuted.value ? 0.0 : 1.0),
    );
    _syncRuntimeHints(isAudible: _currentIsAudible());
  }

  void _resumePlaybackIfEligible({
    String source = 'resume_unspecified',
  }) {
    if (!widget.model.hasPlayableVideo) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'no_playable_video',
      );
      return;
    }
    if (!widget.shouldPlay) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'should_play_false',
      );
      return;
    }
    if (!_isSurfacePlaybackAllowed) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'surface_playback_blocked',
      );
      return;
    }

    final adapter = _videoAdapter;
    if (adapter == null) {
      _recordPlaybackDispatch(
        'feed_card_init_requested',
        source: source,
        dispatchIssued: false,
        skipReason: 'adapter_missing',
      );
      _initVideoController();
      return;
    }

    if (!shouldLoopVideo && adapter.value.isCompleted) {
      _recordPlaybackDispatch(
        'feed_card_completion_blocked',
        source: source,
        dispatchIssued: false,
        skipReason: 'completed',
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
          'durationMs': adapter.value.duration.inMilliseconds,
        },
      );
      return;
    }

    _applyPlaybackVolume();
    if (adapter.value.isInitialized) {
      _recordPlaybackDispatch(
        'feed_card_resume_initialized',
        source: source,
        dispatchIssued: false,
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
        },
      );
      _startPlayback(source: '$source:resume_initialized');
      return;
    }

    if (_useLegacyIosFeedBehavior) {
      _recordPlaybackDispatch(
        'feed_card_legacy_wait_for_init',
        source: source,
        dispatchIssued: false,
        skipReason: 'awaiting_init',
      );
      unawaited(adapter.setLooping(shouldLoopVideo));
      return;
    }

    _recordPlaybackDispatch(
      'feed_card_wait_for_init',
      source: source,
      dispatchIssued: false,
      skipReason: 'adapter_uninitialized',
    );
    unawaited(adapter.setLooping(shouldLoopVideo));
  }

  void _startPlayback({
    String source = 'start_unspecified',
  }) {
    final adapter = _videoAdapter;
    if (adapter == null) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'adapter_missing',
      );
      return;
    }
    if (!_isSurfacePlaybackAllowed) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'surface_playback_blocked',
      );
      return;
    }
    if (!shouldLoopVideo && adapter.value.isCompleted) {
      _recordPlaybackDispatch(
        'feed_card_start_blocked_completed',
        source: source,
        dispatchIssued: false,
        skipReason: 'completed',
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
          'durationMs': adapter.value.duration.inMilliseconds,
        },
      );
      return;
    }
    _recordPlaybackDispatch(
      'feed_card_start_playback',
      source: source,
      dispatchIssued: false,
      metadata: <String, dynamic>{
        'positionMs': adapter.value.position.inMilliseconds,
      },
    );
    unawaited(adapter.setLooping(shouldLoopVideo));
    _applyPlaybackVolume();
    _hasAutoPlayed = true;
    if (!adapter.value.isPlaying) {
      _recordPlaybackDispatch(
        'feed_card_adapter_play',
        source: source,
      );
      unawaited(adapter.play());
    } else {
      _recordPlaybackDispatch(
        'feed_card_adapter_play_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'already_playing',
      );
    }
    if (isStandalonePostInstance) {
      _recordPlaybackDispatch(
        'feed_card_exclusive_play_only_this',
        source: source,
      );
      videoStateManager.playOnlyThis(playbackHandleKey);
    } else if (videoStateManager.currentPlayingDocID != playbackHandleKey) {
      // Feed card already issues adapter.play() above. Using requestPlayVideo
      // here avoids VideoStateManager's delayed second play wave, which can
      // stall the renderer while audio keeps flowing on some Android devices.
      _recordPlaybackDispatch(
        'feed_card_video_state_request',
        source: source,
      );
      videoStateManager.requestPlayVideo(
        playbackHandleKey,
        HLSAdapterPlaybackHandle(adapter),
      );
    } else {
      _recordPlaybackDispatch(
        'feed_card_video_state_request_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'already_current_playing',
      );
    }
    _syncRuntimeHints(
      isAudible: _currentIsAudible(),
      hasStableFocus: true,
    );
    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted || !widget.shouldPlay || _videoAdapter != adapter) return;
      if (!_isSurfacePlaybackAllowed) return;
      _applyPlaybackVolume();
    });
    _trackPlaybackIntent();
    try {
      SegmentCacheManager.maybeFind()?.markPlaying(widget.model.docID);
    } catch (_) {}
  }

  /// Alt sınıflar route geçişinde bir sonraki otomatik pause'u atlamak istediğinde çağırır.
  void markSkipNextPause() {
    _skipNextPause = true;
  }

  /// Fullscreen route açıkken feed tarafında aynı controller'a pause gitmesini engeller.
  void setPauseBlocked(bool value) {
    _blockPause = value;
    if (!value) {
      _skipNextPause = false;
    }
  }

  void tryAutoPlayWhenBuffered() {
    // Adapter initialize olmadan çağrı gelirse pending-play kuyruğa alınır.
    if (_videoAdapter != null) {
      _recordPlaybackDispatch(
        'feed_card_buffer_ready_play',
        source: 'buffer_ready',
      );
      unawaited(_videoAdapter!.setLooping(shouldLoopVideo));
      _videoAdapter!.play();
    }
  }

  Future<void> replayVideoFromStart() async {
    final adapter = _videoAdapter;
    if (adapter == null) return;
    _recordPlaybackDispatch(
      'feed_card_replay_from_start',
      source: 'replay_button',
      dispatchIssued: false,
    );
    _replayOverlayLatched = false;
    _replayAdPrewarmed = false;
    _replayAdVisible = false;
    _replayButtonVisible = false;
    _replayAdImpressionReceived = false;
    _replayAdHideTimer?.cancel();
    await adapter.setLooping(shouldLoopVideo);
    await adapter.seekTo(Duration.zero);
    _startPlayback(source: 'replay_button');
  }

  void _onReplayAdImpression() {
    if (_replayAdImpressionReceived) return;
    _replayAdImpressionReceived = true;
  }

  Widget buildFeedReplayOverlay(HLSVideoValue value) {
    if (!_isReplayOverlayEnabled) return const SizedBox.shrink();
    if (!_replayOverlayLatched && !_replayAdVisible && !_replayButtonVisible) {
      return const SizedBox.shrink();
    }
    final showReplayButton = _replayButtonVisible;
    final showAdPanel = _replayAdVisible;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: showReplayButton ? 0.28 : 0.18),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (showAdPanel) ...[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 300,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: AdmobKare(
                                  showChrome: false,
                                  onImpression: _onReplayAdImpression,
                                ),
                              ),
                              if (showReplayButton) const SizedBox(height: 16),
                              if (showReplayButton)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      unawaited(replayVideoFromStart()),
                                  child: Container(
                                    width: 148,
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Tekrar izle',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontFamily: 'MontserratSemiBold',
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ],
                        if (showReplayButton && !showAdPanel)
                          Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => unawaited(replayVideoFromStart()),
                              child: Container(
                                width: 148,
                                height: 44,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Tekrar izle',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'MontserratSemiBold',
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void reportMediaVisibility(double visibleFraction) {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.onPostVisibilityChanged(modelIndex, visibleFraction);
    }

    final surfaceTag = widget.instanceTag ?? '';
    if (visibleFraction < 0.55) return;

    final profileController = ProfileController.maybeFind();
    if (surfaceTag.startsWith('profile_') && profileController != null) {
      final profileIndex = profileController.indexOfMergedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (profileIndex >= 0) {
        profileController.currentVisibleIndex.value = profileIndex;
        profileController.capturePendingCenteredEntry(
          preferredIndex: profileIndex,
        );
        if (visibleFraction >= 0.72) {
          profileController.centeredIndex.value = profileIndex;
          profileController.lastCenteredIndex = profileIndex;
        }
      }
    }

    final socialProfileController = SocialProfileController.maybeFind();
    if (surfaceTag.startsWith('social_') && socialProfileController != null) {
      final socialIndex = socialProfileController.indexOfCombinedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (socialIndex >= 0) {
        socialProfileController.currentVisibleIndex.value = socialIndex;
        socialProfileController.capturePendingCenteredEntry(
          preferredIndex: socialIndex,
        );
        if (visibleFraction >= 0.72) {
          socialProfileController.centeredIndex.value = socialIndex;
          socialProfileController.lastCenteredIndex = socialIndex;
        }
      }
    }

    if (surfaceTag.startsWith('archives_')) {
      final archiveController = ArchiveController.maybeFind();
      if (archiveController == null) return;
      final archiveIndex = archiveController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (archiveIndex >= 0) {
        archiveController.currentVisibleIndex.value = archiveIndex;
        archiveController.capturePendingCenteredEntry(
          preferredIndex: archiveIndex,
        );
        if (visibleFraction >= 0.72) {
          archiveController.centeredIndex.value = archiveIndex;
          archiveController.lastCenteredIndex = archiveIndex;
        }
      }
    }

    if (surfaceTag.startsWith('liked_post_')) {
      final likedController = LikedPostControllers.maybeFind();
      if (likedController == null) return;
      final likedIndex =
          likedController.all.indexWhere((p) => p.docID == widget.model.docID);
      if (likedIndex >= 0) {
        likedController.currentVisibleIndex.value = likedIndex;
        likedController.capturePendingCenteredEntry(preferredIndex: likedIndex);
        if (visibleFraction >= 0.72) {
          likedController.centeredIndex.value = likedIndex;
          likedController.lastCenteredIndex = likedIndex;
        }
      }
    }

    if (surfaceTag.startsWith('top_tag_')) {
      final topTagsController = TopTagsController.maybeFind();
      if (topTagsController == null) return;
      final topTagsIndex = topTagsController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (topTagsIndex >= 0) {
        topTagsController.currentVisibleIndex.value = topTagsIndex;
        topTagsController.capturePendingCenteredEntry(
          preferredIndex: topTagsIndex,
        );
        if (visibleFraction >= 0.72) {
          topTagsController.centeredIndex.value = topTagsIndex;
          topTagsController.lastCenteredIndex = topTagsIndex;
        }
      }
    }

    if (surfaceTag.startsWith('tag_post_')) {
      final tagPostsController = TagPostsController.maybeFind();
      if (tagPostsController == null) return;
      final tagPostIndex = tagPostsController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (tagPostIndex >= 0) {
        tagPostsController.currentVisibleIndex.value = tagPostIndex;
        tagPostsController.capturePendingCenteredEntry(
          preferredIndex: tagPostIndex,
        );
        if (visibleFraction >= 0.72) {
          tagPostsController.centeredIndex.value = tagPostIndex;
          tagPostsController.lastCenteredIndex = tagPostIndex;
        }
      }
    }

    if (surfaceTag.startsWith('flood_')) {
      final floodController = FloodListingController.maybeFind();
      if (floodController == null) return;
      final floodIndex = floodController.floods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.currentVisibleIndex.value = floodIndex;
        floodController.capturePendingCenteredEntry(preferredIndex: floodIndex);
        if (visibleFraction >= 0.72) {
          floodController.centeredIndex.value = floodIndex;
          floodController.lastCenteredIndex = floodIndex;
        }
      }
    }

    final exploreController = ExploreController.maybeFind();
    if (surfaceTag.startsWith('explore_series_') && exploreController != null) {
      final exploreIndex = exploreController.exploreFloods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (exploreIndex >= 0) {
        exploreController.floodsVisibleIndex.value = exploreIndex;
        exploreController.capturePendingFloodEntry(
          preferredIndex: exploreIndex,
        );
        if (visibleFraction >= 0.72) {
          exploreController.lastFloodVisibleIndex = exploreIndex;
        }
      }
    }
  }

  void onPostInitialized() {}

  bool _currentIsAudible() {
    if (isStandalonePostInstance) return true;
    return !agendaController.isMuted.value;
  }

  void _syncRuntimeHints({
    bool? isAudible,
    bool? hasStableFocus,
  }) {
    VideoTelemetryService.instance.updateRuntimeHints(
      widget.model.docID,
      isAudible: isAudible,
      hasStableFocus: hasStableFocus,
    );
  }

  void _trackPlaybackIntent() {
    if (_playbackIntentTracked) return;
    final playbackKpi = PlaybackKpiService.maybeFind();
    if (playbackKpi == null) return;
    _playbackIntentTracked = true;
    playbackKpi.track(
      PlaybackKpiEventType.playbackIntent,
      {
        'surface': isStandalonePostInstance ? 'single_post' : 'feed_post',
        'videoId': widget.model.docID,
        'audible': _currentIsAudible(),
        'stableFocus': true,
      },
    );
  }
}
