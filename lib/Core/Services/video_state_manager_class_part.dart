part of 'video_state_manager.dart';

/// Instagram tarzı akıcı video deneyimi için video durumu yöneticisi
/// Her videonun oynatma pozisyonunu ve durumunu bellekte tutar
class VideoStateManager extends GetxController {
  static VideoStateManager get instance {
    return ensureVideoStateManager();
  }

  final _VideoStateManagerState _state = _VideoStateManagerState();

  @override
  void onClose() {
    _handleVideoStateManagerClose(this);
    super.onClose();
  }
}
