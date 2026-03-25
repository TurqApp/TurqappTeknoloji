import 'dart:async';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';

part 'video_state_manager_playback_part.dart';

/// Instagram tarzı akıcı video deneyimi için video durumu yöneticisi
/// Her videonun oynatma pozisyonunu ve durumunu bellekte tutar
class VideoStateManager extends GetxController {
  static VideoStateManager? maybeFind() {
    final isRegistered = Get.isRegistered<VideoStateManager>();
    if (!isRegistered) return null;
    return Get.find<VideoStateManager>();
  }

  static VideoStateManager ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(VideoStateManager());
  }

  static VideoStateManager get instance {
    return ensure();
  }

  // Video docID -> VideoState mapping
  final Map<String, VideoState> _videoStates = {};

  // TÜM video controller'ları track et (PlaybackHandle abstract)
  // Max 30 entry — daha eski kayıtlar LRU mantığıyla silinir (bellek sızıntısı önleme)
  static const int _maxTrackedControllers = 30;
  final Map<String, PlaybackHandle> _allVideoControllers = {};

  // GLOBAL VIDEO CONTROL: Şu anda çalan video
  String? _currentPlayingDocID;
  bool _exclusiveMode = false;
  String? _exclusiveDocID;
  Timer? _pendingPlayTimer;
  static const Duration _playResumeDelay = Duration(milliseconds: 140);
  int _playRequestSeq = 0;

  /// Şu anda çalan video ID'sini döndür
  String? get currentPlayingDocID => _currentPlayingDocID;

  void saveVideoState(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this).saveVideoState(docID, handle);

  void saveVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          .saveVideoStateFromController(docID, controller);

  VideoState? getVideoState(String docID) =>
      VideoStateManagerPlaybackPart(this).getVideoState(docID);

  void clearVideoState(String docID) =>
      VideoStateManagerPlaybackPart(this).clearVideoState(docID);

  void clearAllStates() => VideoStateManagerPlaybackPart(this).clearAllStates();

  void cleanOldStates() => VideoStateManagerPlaybackPart(this).cleanOldStates();

  Future<void> restoreVideoState(
    String docID,
    PlaybackHandle handle,
  ) =>
      VideoStateManagerPlaybackPart(this).restoreVideoState(docID, handle);

  Future<void> restoreVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          .restoreVideoStateFromController(docID, controller);

  void updatePosition(String docID, Duration position) =>
      VideoStateManagerPlaybackPart(this).updatePosition(docID, position);

  void registerPlaybackHandle(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this).registerPlaybackHandle(docID, handle);

  void registerVideoController(
          String docID, VideoPlayerController controller) =>
      VideoStateManagerPlaybackPart(this)
          .registerVideoController(docID, controller);

  void unregisterVideoController(String docID) =>
      VideoStateManagerPlaybackPart(this).unregisterVideoController(docID);

  void pauseAllExcept(String? allowedDocID) =>
      VideoStateManagerPlaybackPart(this).pauseAllExcept(allowedDocID);

  void playOnlyThis(String docID) =>
      VideoStateManagerPlaybackPart(this).playOnlyThis(docID);

  void reassertOnlyThis(String docID) =>
      VideoStateManagerPlaybackPart(this).reassertOnlyThis(docID);

  void requestPlayVideo(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this).requestPlayVideo(docID, handle);

  void requestPlayVideoFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          .requestPlayVideoFromController(docID, controller);

  void requestStopVideo(String docID) =>
      VideoStateManagerPlaybackPart(this).requestStopVideo(docID);

  void pauseAllVideos({bool force = false}) =>
      VideoStateManagerPlaybackPart(this).pauseAllVideos(force: force);

  void enterExclusiveMode(String docID) =>
      VideoStateManagerPlaybackPart(this).enterExclusiveMode(docID);

  void updateExclusiveModeDoc(String docID) =>
      VideoStateManagerPlaybackPart(this).updateExclusiveModeDoc(docID);

  void exitExclusiveMode() =>
      VideoStateManagerPlaybackPart(this).exitExclusiveMode();

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
