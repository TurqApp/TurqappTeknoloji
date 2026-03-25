part of 'video_state_manager.dart';

extension VideoStateManagerFacadePart on VideoStateManager {
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
    String docID,
    VideoPlayerController controller,
  ) =>
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
}
