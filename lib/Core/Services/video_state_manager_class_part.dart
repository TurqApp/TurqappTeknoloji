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

  final _VideoStateManagerState _state = _VideoStateManagerState();
  static const int _maxTrackedControllers = 30;
  static const Duration _playResumeDelay = Duration(milliseconds: 140);

  @override
  void onClose() {
    _handleVideoStateManagerClose(this);
    super.onClose();
  }
}
