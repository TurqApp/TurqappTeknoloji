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
part 'post_content_base_playback_part.dart';
part 'post_content_base_visibility_part.dart';

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
      ensureGlobalVideoAdapterPool();
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
    return ensureAgendaController();
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
    if (!_isProfileFamilySurfaceInstance) {
      return agendaController.canClaimPlaybackNow;
    }
    final nav = NavBarController.maybeFind();
    final settings = maybeFindSettingsController();
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

  void onPostInitialized() {}
}
