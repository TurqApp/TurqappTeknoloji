part of 'creator_content_controller.dart';

class _CreatorContentControllerState {
  final textEdit = TextEditingController();
  final picker = ImagePicker();
  final cropController = CropController();
  final selectedImages = <File>[].obs;
  final selectedVideo = Rx<File?>(null);
  final croppedImages = <Uint8List?>[].obs;
  final isCropping = false.obs;
  final isPlaying = false.obs;
  final hasVideo = false.obs;
  final isProcessing = false.obs;
  final focus = FocusNode();
  final isFocusedOnce = false.obs;
  final contentNotEmpty = false.obs;
  final textChanged = false.obs;
  final waitingVideo = false.obs;
  final trendingHashtags = <HashtagModel>[].obs;
  final hashtagSuggestions = <HashtagModel>[].obs;
  final showHashtagSuggestions = false.obs;
  final hashtagSuggestionsLoading = false.obs;
  final activeHashtagQuery = ''.obs;
  final reusedVideoUrl = ''.obs;
  final reusedVideoThumbnail = ''.obs;
  final reusedVideoAspectRatio = 0.0.obs;
  final reusedImageAspectRatio = 0.0.obs;
  final reusedImageUrls = <String>[].obs;
  final videoLookPreset = 'original'.obs;
  final selectedThumbnail = Rx<Uint8List?>(null);
  final pollData = Rxn<Map<String, dynamic>>();
  final adres = ''.obs;
  final gif = ''.obs;
  final rxVideoPlayerController = Rx<VideoPlayerController?>(null);
}

extension CreatorContentControllerFieldsPart on CreatorContentController {
  TextEditingController get textEdit => _state.textEdit;
  ImagePicker get picker => _state.picker;
  CropController get cropController => _state.cropController;
  RxList<File> get selectedImages => _state.selectedImages;
  Rx<File?> get selectedVideo => _state.selectedVideo;
  RxList<Uint8List?> get croppedImages => _state.croppedImages;
  RxBool get isCropping => _state.isCropping;
  RxBool get isPlaying => _state.isPlaying;
  RxBool get hasVideo => _state.hasVideo;
  RxBool get isProcessing => _state.isProcessing;
  FocusNode get focus => _state.focus;
  RxBool get isFocusedOnce => _state.isFocusedOnce;
  RxBool get contentNotEmpty => _state.contentNotEmpty;
  RxBool get textChanged => _state.textChanged;
  RxBool get waitingVideo => _state.waitingVideo;
  RxList<HashtagModel> get trendingHashtags => _state.trendingHashtags;
  RxList<HashtagModel> get hashtagSuggestions => _state.hashtagSuggestions;
  RxBool get showHashtagSuggestions => _state.showHashtagSuggestions;
  RxBool get hashtagSuggestionsLoading => _state.hashtagSuggestionsLoading;
  RxString get activeHashtagQuery => _state.activeHashtagQuery;
  RxString get reusedVideoUrl => _state.reusedVideoUrl;
  RxString get reusedVideoThumbnail => _state.reusedVideoThumbnail;
  RxDouble get reusedVideoAspectRatio => _state.reusedVideoAspectRatio;
  RxDouble get reusedImageAspectRatio => _state.reusedImageAspectRatio;
  RxList<String> get reusedImageUrls => _state.reusedImageUrls;
  RxString get videoLookPreset => _state.videoLookPreset;
  Rx<Uint8List?> get selectedThumbnail => _state.selectedThumbnail;
  Rxn<Map<String, dynamic>> get pollData => _state.pollData;
  RxString get adres => _state.adres;
  RxString get gif => _state.gif;
  Rx<VideoPlayerController?> get rxVideoPlayerController =>
      _state.rxVideoPlayerController;
}
