import 'dart:async';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Core/Services/PlaybackHandle.dart';

/// Instagram tarzı akıcı video deneyimi için video durumu yöneticisi
/// Her videonun oynatma pozisyonunu ve durumunu bellekte tutar
class VideoStateManager extends GetxController {
  static VideoStateManager get instance {
    if (!Get.isRegistered<VideoStateManager>()) {
      Get.put(VideoStateManager());
    }
    return Get.find<VideoStateManager>();
  }

  // Video docID -> VideoState mapping
  final Map<String, VideoState> _videoStates = {};

  // TÜM video controller'ları track et (PlaybackHandle abstract)
  final Map<String, PlaybackHandle> _allVideoControllers = {};

  // GLOBAL VIDEO CONTROL: Şu anda çalan video
  String? _currentPlayingDocID;
  Timer? _pendingPlayTimer;
  static const Duration _playResumeDelay = Duration(milliseconds: 140);

  /// Video durumunu kaydet (PlaybackHandle ile)
  void saveVideoState(String docID, PlaybackHandle handle) {
    if (!handle.isInitialized) return;

    _videoStates[docID] = VideoState(
      position: handle.position,
      isPlaying: handle.isPlaying,
      lastUpdated: DateTime.now(),
    );
  }

  /// Legacy: VideoPlayerController ile kaydet
  void saveVideoStateFromController(String docID, VideoPlayerController controller) {
    if (!controller.value.isInitialized) return;

    _videoStates[docID] = VideoState(
      position: controller.value.position,
      isPlaying: controller.value.isPlaying,
      lastUpdated: DateTime.now(),
    );
  }

  /// Kaydedilmiş video durumunu getir
  VideoState? getVideoState(String docID) {
    return _videoStates[docID];
  }

  /// Video durumunu temizle (video dispose edildiğinde)
  void clearVideoState(String docID) {
    _videoStates.remove(docID);
  }

  /// Tüm video durumlarını temizle
  void clearAllStates() {
    _videoStates.clear();
  }

  /// Eski durumları temizle (5 dakikadan eski)
  void cleanOldStates() {
    final now = DateTime.now();
    _videoStates.removeWhere((key, state) {
      return now.difference(state.lastUpdated).inMinutes > 5;
    });
  }

  /// Video controller'ı kaydedilmiş duruma göre ayarla (PlaybackHandle)
  Future<void> restoreVideoState(
    String docID,
    PlaybackHandle handle,
  ) async {
    final state = getVideoState(docID);
    if (state == null || !handle.isInitialized) return;

    if (state.position.inMilliseconds > 0) {
      await handle.seekTo(state.position);
    }
  }

  /// Legacy: VideoPlayerController ile restore
  Future<void> restoreVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) async {
    final state = getVideoState(docID);
    if (state == null || !controller.value.isInitialized) return;

    if (state.position.inMilliseconds > 0) {
      await controller.seekTo(state.position);
    }
  }

  /// Video pozisyonunu güncelle (sürekli güncelleme için)
  void updatePosition(String docID, Duration position) {
    final state = _videoStates[docID];
    if (state != null) {
      _videoStates[docID] = VideoState(
        position: position,
        isPlaying: state.isPlaying,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Video handle kaydet (PlaybackHandle)
  void registerPlaybackHandle(String docID, PlaybackHandle handle) {
    _allVideoControllers[docID] = handle;
  }

  /// Legacy: VideoPlayerController kaydet
  void registerVideoController(String docID, VideoPlayerController controller) {
    _allVideoControllers[docID] = LegacyPlaybackHandle(controller);
  }

  /// Video handle kaldır
  void unregisterVideoController(String docID) {
    _allVideoControllers.remove(docID);
    if (_currentPlayingDocID == docID) {
      _pendingPlayTimer?.cancel();
      _pendingPlayTimer = null;
    }
    if (_currentPlayingDocID == docID) {
      _currentPlayingDocID = null;
    }
  }

  /// INSTAGRAM STYLE: TÜM videoları durdur, sadece belirtileni oynat
  void pauseAllExcept(String? allowedDocID) {
    for (final entry in _allVideoControllers.entries) {
      if (entry.key == allowedDocID) continue;

      try {
        final handle = entry.value;
        if (handle.isInitialized && handle.isPlaying) {
          handle.pause();
        }
      } catch (e) {
        // Hata varsa sessizce devam et
      }
    }

    if (allowedDocID != null) {
      _currentPlayingDocID = allowedDocID;
    } else {
      _currentPlayingDocID = null;
    }
  }

  /// INSTAGRAM STYLE: SADECE bu videoyu oynat, diğer tüm videoları durdur
  void playOnlyThis(String docID) {
    final current = _allVideoControllers[docID];
    if (_currentPlayingDocID == docID &&
        current != null &&
        current.isInitialized &&
        current.isPlaying) {
      return;
    }

    pauseAllExcept(docID);

    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = Timer(_playResumeDelay, () {
      if (_currentPlayingDocID != docID) return;
      final handle = _allVideoControllers[docID];
      if (handle != null && handle.isInitialized && !handle.isPlaying) {
        handle.play();
      }
    });
  }

  /// GLOBAL VIDEO CONTROL: Video oynatma isteği
  void requestPlayVideo(String docID, PlaybackHandle handle) {
    _allVideoControllers[docID] = handle;
    pauseAllExcept(docID);
    _currentPlayingDocID = docID;
  }

  /// Legacy: VideoPlayerController ile requestPlayVideo
  void requestPlayVideoFromController(String docID, VideoPlayerController controller) {
    requestPlayVideo(docID, LegacyPlaybackHandle(controller));
  }

  /// Video durdurma isteği
  void requestStopVideo(String docID) {
    if (_currentPlayingDocID == docID) {
      _currentPlayingDocID = null;
    }
  }

  /// INSTAGRAM STYLE: TÜM videoları durdur
  void pauseAllVideos() {
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    pauseAllExcept(null);
  }

  /// Şu anda çalan video ID'sini döndür
  String? get currentPlayingDocID => _currentPlayingDocID;

  @override
  void onClose() {
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    super.onClose();
  }
}

/// Video durum modeli
class VideoState {
  final Duration position;
  final bool isPlaying;
  final DateTime lastUpdated;

  VideoState({
    required this.position,
    required this.isPlaying,
    required this.lastUpdated,
  });

  VideoState copyWith({
    Duration? position,
    bool? isPlaying,
    DateTime? lastUpdated,
  }) {
    return VideoState(
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
