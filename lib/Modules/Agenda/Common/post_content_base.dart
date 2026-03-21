import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/posts_model.dart';
import '../../../main.dart';
import '../../../hls_player/hls_video_adapter.dart';
import '../../../Core/Services/SegmentCache/cache_manager.dart';
import '../../../Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import '../../../Core/Services/video_state_manager.dart';
import '../../../Core/Services/video_telemetry_service.dart';
import '../../../Core/Services/playback_handle.dart';
import '../../../Core/Services/global_video_adapter_pool.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Explore/explore_controller.dart';
import '../../Profile/MyProfile/profile_controller.dart';
import '../../Profile/Archives/archives_controller.dart';
import '../../Profile/LikedPosts/liked_posts_controller.dart';
import '../../SocialProfile/social_profile_controller.dart';
import '../../Agenda/TopTags/top_tags_contoller.dart';
import '../../Agenda/TagPosts/tag_posts_controller.dart';
import '../../Agenda/FloodListing/flood_listing_controller.dart';
import 'post_content_controller.dart';

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
  late final GlobalVideoAdapterPool adapterPool = GlobalVideoAdapterPool.ensure();
  final videoStateManager = VideoStateManager.instance;

  late final PostContentController controller;
  HLSVideoAdapter? _videoAdapter;
  bool _hasAutoPlayed = false;
  bool _skipNextPause = false;
  bool _blockPause = false;
  Worker? _muteWorker;
  Worker? _pauseAllWorker;
  Timer? _lazyInitTimer;
  bool _playbackIntentTracked = false;

  /// Video state'i sadece süre/replay göstergesini güncellemek için.
  /// setState yerine ValueNotifier kullanarak tüm post'u rebuild etmekten kaçınıyoruz.
  final ValueNotifier<HLSVideoValue> videoValueNotifier =
      ValueNotifier(const HLSVideoValue());

  AgendaController _resolveAgendaController() {
    if (Get.isRegistered<AgendaController>()) {
      return Get.find<AgendaController>();
    }
    return Get.put(AgendaController());
  }

  /// videoController benzeri erişim — mevcut widget'lar uyumlu çalışır
  HLSVideoAdapter? get videoController => _videoAdapter;

  bool get isVideoFromCache {
    if (!widget.model.hasPlayableVideo) return false;
    try {
      if (!Get.isRegistered<SegmentCacheManager>()) return false;
      final entry =
          Get.find<SegmentCacheManager>().getEntry(widget.model.docID);
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

  bool get shouldLoopVideo => isStandalonePostInstance;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<PostContentController>(tag: controllerTag)) {
      controller = Get.find<PostContentController>(tag: controllerTag);
    } else {
      controller = Get.put(widget.createController(), tag: controllerTag);
    }

    if (widget.showArchivePost) {
      controller.arsiv.value = false;
    }

    // iOS'ta aynı anda çok sayıda native player açılması "ses var görüntü yok"
    // ve raster crash'e yol açabiliyor. Player'ı yalnızca oynatma gerektiğinde aç.
    // Hızlı scroll sırasında native view oluşturmayı engellemek için kısa gecikme.
    if (widget.model.hasPlayableVideo && widget.shouldPlay) {
      final delay = isStandalonePostInstance
          ? Duration.zero
          : const Duration(milliseconds: 150);
      _lazyInitTimer = Timer(delay, () {
        if (!mounted) return;
        if (widget.shouldPlay) {
          _initVideoController();
          if (isStandalonePostInstance) {
            Future.delayed(const Duration(milliseconds: 220), () {
              if (!mounted || _videoAdapter == null || !widget.shouldPlay) {
                return;
              }
              _videoAdapter!.setVolume(1.0);
              _videoAdapter!.play();
              videoStateManager.playOnlyThis(playbackHandleKey);
              Future.delayed(const Duration(milliseconds: 220), () {
                if (!mounted || _videoAdapter == null || !widget.shouldPlay) {
                  return;
                }
                _videoAdapter!.setVolume(1.0);
              });
            });
          }
        }
      });
    }

    if (widget.showComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          controller.showPostCommentsBottomSheet();
          _videoAdapter?.setLooping(false);
        });
      });
    }

    onPostInitialized();
  }

  void _initVideoController() {
    if (_videoAdapter != null) return;
    _videoAdapter = adapterPool.acquire(
      cacheKey: playbackHandleKey,
      url: widget.model.playbackUrl,
      autoPlay: widget.shouldPlay,
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
        }
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    try {
      final route = ModalRoute.of(context);
      if (route != null) routeObserver.unsubscribe(this);
    } catch (_) {}

    _lazyInitTimer?.cancel();
    _videoAdapter?.removeListener(_onVideoUpdate);
    if (isStandalonePostInstance) {
      videoStateManager.exitExclusiveMode();
    }
    videoStateManager.unregisterVideoController(playbackHandleKey);
    final adapter = _videoAdapter;
    if (adapter != null) {
      unawaited(adapterPool.release(adapter));
    }
    _muteWorker?.dispose();
    _pauseAllWorker?.dispose();
    videoValueNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.shouldPlay != widget.shouldPlay) {
      if (widget.shouldPlay) {
        _lazyInitTimer?.cancel();
        if (_videoAdapter == null && widget.model.hasPlayableVideo) {
          _initVideoController();
        }
        if (isStandalonePostInstance) {
          videoStateManager.enterExclusiveMode(playbackHandleKey);
        }
        if (_videoAdapter?.value.isInitialized == true) {
          _startPlayback();
        }
      } else {
        // Bekleyen lazy init varsa iptal et
        _lazyInitTimer?.cancel();
        if (_blockPause) return;
        // Fullscreen geçişi sırasında pause etme
        if (_skipNextPause) {
          _skipNextPause = false;
          return;
        }
        _safePauseVideo();
      }
    }
  }

  @override
  void didPushNext() {
    if (_blockPause) return;
    if (_skipNextPause) {
      _skipNextPause = false;
      return;
    }
    _safePauseVideo();
  }

  @override
  void didPopNext() {
    if (widget.shouldPlay && _videoAdapter != null) {
      if (isStandalonePostInstance) {
        videoStateManager.enterExclusiveMode(playbackHandleKey);
      }
      if (_videoAdapter!.value.isInitialized) {
        _startPlayback();
      }
    }
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  void _onVideoUpdate() {
    if (!mounted) return;
    final v = _videoAdapter!.value;

    // İlk kez ready olduğunda ses ayarla
    if (v.isInitialized && !_hasAutoPlayed) {
      if (widget.shouldPlay) {
        _startPlayback();
      } else {
        _applyPlaybackVolume();
      }
    }

    // Watch progress bildirimi (feed videoları için)
    if (v.isInitialized && v.duration.inMilliseconds > 0) {
      final progress = v.position.inMilliseconds / v.duration.inMilliseconds;
      if (progress > 0) {
        try {
          Get.find<SegmentCacheManager>()
              .updateWatchProgress(widget.model.docID, progress);
        } catch (_) {}
      }
    }

    // Sadece video overlay'lerini güncelle — tüm post'u rebuild etme
    videoValueNotifier.value = v;
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

  void _startPlayback() {
    final adapter = _videoAdapter;
    if (adapter == null) return;
    unawaited(adapter.setLooping(shouldLoopVideo));
    _applyPlaybackVolume();
    _hasAutoPlayed = true;
    unawaited(adapter.play());
    videoStateManager.playOnlyThis(playbackHandleKey);
    _syncRuntimeHints(
      isAudible: _currentIsAudible(),
      hasStableFocus: true,
    );
    _trackPlaybackIntent();
    try {
      Get.find<SegmentCacheManager>().markPlaying(widget.model.docID);
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
      unawaited(_videoAdapter!.setLooping(shouldLoopVideo));
      _videoAdapter!.play();
    }
  }

  Future<void> replayVideoFromStart() async {
    final adapter = _videoAdapter;
    if (adapter == null) return;
    await adapter.setLooping(shouldLoopVideo);
    await adapter.seekTo(Duration.zero);
    _startPlayback();
  }

  Widget buildFeedReplayOverlay(HLSVideoValue value) {
    if (isStandalonePostInstance) return const SizedBox.shrink();
    if (!value.isCompleted) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.28),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(replayVideoFromStart()),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 42,
                  maxWidth: 148,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Tekrar izle',
                    maxLines: 1,
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

    if (surfaceTag.startsWith('profile_') &&
        Get.isRegistered<ProfileController>()) {
      final profileController = Get.find<ProfileController>();
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

    if (surfaceTag.startsWith('social_') &&
        Get.isRegistered<SocialProfileController>()) {
      final socialProfileController = Get.find<SocialProfileController>();
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

    if (surfaceTag.startsWith('archives_') &&
        Get.isRegistered<ArchiveController>()) {
      final archiveController = Get.find<ArchiveController>();
      final archiveIndex =
          archiveController.list.indexWhere((p) => p.docID == widget.model.docID);
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

    if (surfaceTag.startsWith('liked_post_') &&
        Get.isRegistered<LikedPostControllers>()) {
      final likedController = Get.find<LikedPostControllers>();
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

    if (surfaceTag.startsWith('top_tag_') &&
        Get.isRegistered<TopTagsController>()) {
      final topTagsController = Get.find<TopTagsController>();
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

    if (surfaceTag.startsWith('tag_post_') &&
        Get.isRegistered<TagPostsController>()) {
      final tagPostsController = Get.find<TagPostsController>();
      final tagPostIndex =
          tagPostsController.list.indexWhere((p) => p.docID == widget.model.docID);
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

    if (surfaceTag.startsWith('flood_') &&
        Get.isRegistered<FloodListingController>()) {
      final floodController = Get.find<FloodListingController>();
      final floodIndex =
          floodController.floods.indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.currentVisibleIndex.value = floodIndex;
        floodController.capturePendingCenteredEntry(preferredIndex: floodIndex);
        if (visibleFraction >= 0.72) {
          floodController.centeredIndex.value = floodIndex;
          floodController.lastCenteredIndex = floodIndex;
        }
      }
    }

    if (surfaceTag.startsWith('explore_series_') &&
        Get.isRegistered<ExploreController>()) {
      final exploreController = Get.find<ExploreController>();
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
    if (!Get.isRegistered<PlaybackKpiService>()) return;
    _playbackIntentTracked = true;
    Get.find<PlaybackKpiService>().track(
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
