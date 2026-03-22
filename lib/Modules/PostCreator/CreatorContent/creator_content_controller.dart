import 'dart:async';
import 'dart:io';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../../../Core/LocationFinderView/location_finder_view.dart';
import '../../../Core/Services/upload_validation_service.dart';
import '../../../Core/Services/media_compression_service.dart';
import '../../../Core/Services/network_awareness_service.dart';
import '../../../Core/Camera/chat_camera_capture_view.dart';
import '../../../Core/upload_constants.dart';
import '../../../Themes/app_colors.dart';
import '../post_creator_controller.dart';

part 'creator_content_controller_poll_part.dart';
part 'creator_content_controller_media_part.dart';
part 'creator_content_controller_video_part.dart';

class CreatorContentController extends GetxController
    with WidgetsBindingObserver {
  static CreatorContentController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreatorContentController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreatorContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreatorContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreatorContentController>(tag: tag);
  }

  static const List<String> supportedVideoLookPresets = <String>[
    'original',
    'clear',
    'cinema',
    'vibe',
    'bright',
  ];

  TextEditingController textEdit = TextEditingController();
  final ImagePicker picker = ImagePicker();
  final CropController cropController = CropController();

  final RxList<File> selectedImages = <File>[].obs;
  final Rx<File?> selectedVideo = Rx<File?>(null);
  final RxList<Uint8List?> croppedImages = <Uint8List?>[].obs;
  final RxBool isCropping = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool hasVideo = false.obs;
  final RxBool isProcessing = false.obs;
  FocusNode focus = FocusNode();
  final RxBool isFocusedOnce = false.obs;
  final RxBool contentNotEmpty = false.obs;
  final RxBool textChanged = false.obs;
  final RxBool waitingVideo = false.obs;
  final RxString reusedVideoUrl = ''.obs;
  final RxString reusedVideoThumbnail = ''.obs;
  final RxDouble reusedVideoAspectRatio = 0.0.obs;
  final RxDouble reusedImageAspectRatio = 0.0.obs;
  final RxList<String> reusedImageUrls = <String>[].obs;
  final RxString videoLookPreset = 'original'.obs;

  // User-selected custom thumbnail for video posts
  final Rx<Uint8List?> selectedThumbnail = Rx<Uint8List?>(null);

  // Poll data for this post (question + options)
  final Rxn<Map<String, dynamic>> pollData = Rxn<Map<String, dynamic>>();

  var adres = "".obs;
  var gif = "".obs;

  Rx<VideoPlayerController?> rxVideoPlayerController =
      Rx<VideoPlayerController?>(null);

  VideoPlayerController? get videoPlayerController =>
      rxVideoPlayerController.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_releaseVideoController());
    isPlaying.value = false;
    focus.dispose();
    textEdit.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(forcePauseVideo());
    }
  }

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

  /// Opens a bottom sheet to pick a custom thumbnail frame from the selected video
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

  Future<void> resetComposerState() => _performResetComposerState();
}
