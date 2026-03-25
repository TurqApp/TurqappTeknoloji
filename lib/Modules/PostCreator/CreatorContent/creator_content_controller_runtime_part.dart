part of 'creator_content_controller.dart';

extension CreatorContentControllerRuntimeX on CreatorContentController {
  Future<void> openPollComposer() => _performOpenPollComposer();

  Future<void> pickImage() => _performPickImage();

  Future<void> _replaceWithSingleImage({
    required File file,
    required Uint8List compressedData,
  }) =>
      _performReplaceWithSingleImage(
        file: file,
        compressedData: compressedData,
      );

  Future<void> pickImageFromCamera({required ImageSource source}) =>
      _performPickImageFromCamera(source: source);

  Future<void> _processPickedImage(File file) =>
      _performProcessPickedImage(file);

  Future<void> pickVideo({required ImageSource source}) =>
      _performPickVideo(source: source);

  Future<void> _processPickedVideo(File file) =>
      _performProcessPickedVideo(file);

  Future<void> _replaceWithSingleVideo(File file) =>
      _performReplaceWithSingleVideo(file);

  Future<void> setReusedVideoSource({
    required String videoUrl,
    required double aspectRatio,
    String thumbnail = '',
  }) =>
      _performSetReusedVideoSource(
        videoUrl: videoUrl,
        aspectRatio: aspectRatio,
        thumbnail: thumbnail,
      );

  Future<void> setReusedImageSources(
    List<String> imageUrls, {
    double aspectRatio = 0.0,
  }) =>
      _performSetReusedImageSources(
        imageUrls,
        aspectRatio: aspectRatio,
      );

  void setVideoLookPreset(String preset) => _performSetVideoLookPreset(preset);

  Future<void> openCustomCameraCapture() => _performOpenCustomCameraCapture();

  void _enforceImageCap() => _performEnforceImageCap();

  Future<void> openThumbnailPicker() => _performOpenThumbnailPicker();

  Future<void> goToLocationMap() => _performGoToLocationMap();

  void _listenVideo() => _performListenVideo();

  Future<void> playVideo() => _performPlayVideo();

  Future<void> pauseVideo() => _performPauseVideo();

  Future<void> forcePauseVideo() => _performForcePauseVideo();

  Future<void> togglePlayPause() => _performTogglePlayPause();

  void _bindVideoController(VideoPlayerController controller) =>
      _performBindVideoController(controller);

  Future<void> _releaseVideoController() => _performReleaseVideoController();

  Future<void> ensureTrendingHashtagsLoaded() =>
      _performEnsureTrendingHashtagsLoaded();

  void refreshHashtagSuggestionsFromCursor() =>
      _performRefreshHashtagSuggestionsFromCursor();

  void applyTrendingHashtagSelection(HashtagModel model) =>
      _performApplyTrendingHashtagSelection(model);

  Future<void> resetComposerState() => _performResetComposerState();
}
