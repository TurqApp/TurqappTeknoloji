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
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import '../../../Core/LocationFinderView/location_finder_view.dart';
import '../../../Core/Services/upload_validation_service.dart';
import '../../../Core/Services/media_compression_service.dart';
import '../../../Core/Services/network_awareness_service.dart';
import '../../../Core/Camera/chat_camera_capture_view.dart';
import '../../../Core/upload_constants.dart';
import '../../../Themes/app_colors.dart';
import '../post_creator_controller.dart';
import 'composer_hashtag_utils.dart';

part 'creator_content_controller_poll_part.dart';
part 'creator_content_controller_lifecycle_part.dart';
part 'creator_content_controller_media_part.dart';
part 'creator_content_controller_video_part.dart';
part 'creator_content_controller_hashtag_part.dart';
part 'creator_content_controller_runtime_part.dart';

class CreatorContentController extends GetxController
    with WidgetsBindingObserver {
  void _handleTextEditingChanged() =>
      _CreatorContentControllerLifecyclePart(this).handleTextEditingChanged();

  static CreatorContentController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(CreatorContentController(), tag: tag, permanent: permanent);
  }

  static CreatorContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreatorContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreatorContentController>(tag: tag);
  }

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
  final RxList<HashtagModel> trendingHashtags = <HashtagModel>[].obs;
  final RxList<HashtagModel> hashtagSuggestions = <HashtagModel>[].obs;
  final RxBool showHashtagSuggestions = false.obs;
  final RxBool hashtagSuggestionsLoading = false.obs;
  final RxString activeHashtagQuery = ''.obs;
  final RxString reusedVideoUrl = ''.obs;
  final RxString reusedVideoThumbnail = ''.obs;
  final RxDouble reusedVideoAspectRatio = 0.0.obs;
  final RxDouble reusedImageAspectRatio = 0.0.obs;
  final RxList<String> reusedImageUrls = <String>[].obs;
  final RxString videoLookPreset = 'original'.obs;

  final Rx<Uint8List?> selectedThumbnail = Rx<Uint8List?>(null);
  final Rxn<Map<String, dynamic>> pollData = Rxn<Map<String, dynamic>>();

  var adres = "".obs;
  var gif = "".obs;
  final TopTagsRepository _topTagsRepository = TopTagsRepository.ensure();

  Rx<VideoPlayerController?> rxVideoPlayerController =
      Rx<VideoPlayerController?>(null);

  VideoPlayerController? get videoPlayerController =>
      rxVideoPlayerController.value;

  @override
  void onInit() {
    super.onInit();
    _CreatorContentControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _CreatorContentControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _CreatorContentControllerLifecyclePart(this)
          .didChangeAppLifecycleState(state);
}
