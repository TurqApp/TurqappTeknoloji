part of 'video_state_manager.dart';

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

  final Map<String, VideoState> _videoStates = {};

  static const int _maxTrackedControllers = 30;
  final Map<String, PlaybackHandle> _allVideoControllers = {};

  String? _currentPlayingDocID;
  bool _exclusiveMode = false;
  String? _exclusiveDocID;
  Timer? _pendingPlayTimer;
  static const Duration _playResumeDelay = Duration(milliseconds: 140);
  int _playRequestSeq = 0;

  String? get currentPlayingDocID => _currentPlayingDocID;

  bool hasPendingPlayFor(String docID) {
    final timer = _pendingPlayTimer;
    return timer != null &&
        timer.isActive &&
        _currentPlayingDocID == docID;
  }

  bool resumeCurrentPlaybackIfReady(String docID) {
    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return false;
    }
    if (_currentPlayingDocID != docID) return false;
    final handle = _allVideoControllers[docID];
    if (handle == null || !handle.isInitialized) return false;
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    if (!handle.isPlaying) {
      handle.play();
    }
    return true;
  }

  @override
  void onClose() {
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    super.onClose();
  }
}
