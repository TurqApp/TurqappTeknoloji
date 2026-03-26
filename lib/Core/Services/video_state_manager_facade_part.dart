part of 'video_state_manager.dart';

/// Instagram tarzı akıcı video deneyimi için video durumu yöneticisi
/// Her videonun oynatma pozisyonunu ve durumunu bellekte tutar
class VideoStateManager extends GetxController {
  static VideoStateManager get instance => ensureVideoStateManager();

  final _VideoStateManagerState _state = _VideoStateManagerState();

  @override
  void onClose() {
    _handleVideoStateManagerClose(this);
    super.onClose();
  }
}

VideoStateManager? maybeFindVideoStateManager() {
  final isRegistered = Get.isRegistered<VideoStateManager>();
  if (!isRegistered) return null;
  return Get.find<VideoStateManager>();
}

VideoStateManager ensureVideoStateManager() {
  final existing = maybeFindVideoStateManager();
  if (existing != null) return existing;
  return Get.put(VideoStateManager());
}

extension VideoStateManagerFacadePart on VideoStateManager {
  void saveVideoState(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this)._saveVideoState(docID, handle);

  void saveVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._saveVideoStateFromController(docID, controller);

  VideoState? getVideoState(String docID) =>
      VideoStateManagerPlaybackPart(this)._getVideoState(docID);

  void clearVideoState(String docID) =>
      VideoStateManagerPlaybackPart(this)._clearVideoState(docID);

  void clearAllStates() =>
      VideoStateManagerPlaybackPart(this)._clearAllStates();

  void cleanOldStates() =>
      VideoStateManagerPlaybackPart(this)._cleanOldStates();

  Future<void> restoreVideoState(
    String docID,
    PlaybackHandle handle,
  ) =>
      VideoStateManagerPlaybackPart(this)._restoreVideoState(docID, handle);

  Future<void> restoreVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._restoreVideoStateFromController(docID, controller);

  void updatePosition(String docID, Duration position) =>
      VideoStateManagerPlaybackPart(this)._updatePosition(docID, position);

  void registerPlaybackHandle(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this)
          ._registerPlaybackHandle(docID, handle);

  void registerVideoController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._registerVideoController(docID, controller);

  void unregisterVideoController(String docID) =>
      VideoStateManagerPlaybackPart(this)._unregisterVideoController(docID);

  void pauseAllExcept(String? allowedDocID) =>
      VideoStateManagerPlaybackPart(this)._pauseAllExcept(allowedDocID);

  void playOnlyThis(String docID) =>
      VideoStateManagerPlaybackPart(this)._playOnlyThis(docID);

  void reassertOnlyThis(String docID) =>
      VideoStateManagerPlaybackPart(this)._reassertOnlyThis(docID);

  void requestPlayVideo(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this)._requestPlayVideo(docID, handle);

  void requestPlayVideoFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._requestPlayVideoFromController(docID, controller);

  void requestStopVideo(String docID) =>
      VideoStateManagerPlaybackPart(this)._requestStopVideo(docID);

  void pauseAllVideos({bool force = false}) =>
      VideoStateManagerPlaybackPart(this)._pauseAllVideos(force: force);

  void enterExclusiveMode(String docID) =>
      VideoStateManagerPlaybackPart(this)._enterExclusiveMode(docID);

  void updateExclusiveModeDoc(String docID) =>
      VideoStateManagerPlaybackPart(this)._updateExclusiveModeDoc(docID);

  void exitExclusiveMode() =>
      VideoStateManagerPlaybackPart(this)._exitExclusiveMode();
}
