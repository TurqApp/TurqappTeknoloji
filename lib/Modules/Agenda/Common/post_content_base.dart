import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/posts_model.dart';
import '../../../main.dart';
import '../../../hls_player/hls_video_adapter.dart';
import '../../../Core/Services/SegmentCache/cache_manager.dart';
import '../../../Core/Services/video_state_manager.dart';
import '../../../Core/Services/playback_handle.dart';
import '../../Agenda/agenda_controller.dart';
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
  final videoStateManager = VideoStateManager.instance;

  late final PostContentController controller;
  HLSVideoAdapter? _videoAdapter;
  bool _hasAutoPlayed = false;
  bool _skipNextPause = false;
  bool _blockPause = false;
  Worker? _muteWorker;
  Worker? _pauseAllWorker;
  Timer? _lazyInitTimer;

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
    _videoAdapter = HLSVideoAdapter(
      url: widget.model.playbackUrl,
      autoPlay: widget.shouldPlay,
      loop: true,
    );

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
      });
    } else {
      _videoAdapter?.setVolume(1.0);
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
    _videoAdapter?.dispose();
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
        _videoAdapter?.play();
        videoStateManager.playOnlyThis(playbackHandleKey);
        // Cache state machine: playing olarak işaretle
        try {
          Get.find<SegmentCacheManager>().markPlaying(widget.model.docID);
        } catch (_) {}
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
      _videoAdapter?.play();
      videoStateManager.playOnlyThis(playbackHandleKey);
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
      _videoAdapter!.setVolume(
        isStandalonePostInstance
            ? 1.0
            : (agendaController.isMuted.value ? 0.0 : 1.0),
      );
      if (widget.shouldPlay) {
        _hasAutoPlayed = true;
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
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          !isStandalonePostInstance) {
        v.stopPlayback();
      } else {
        v.pause();
      }
      _hasAutoPlayed = false;
    }
  }

  void pauseVideo() => _safePauseVideo();

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
      _videoAdapter!.play();
    }
  }

  void reportMediaVisibility(double visibleFraction) {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex < 0) return;
    agendaController.onPostVisibilityChanged(modelIndex, visibleFraction);
  }

  void onPostInitialized() {}
}
