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

class CreatorContentController extends GetxController
    with WidgetsBindingObserver {
  static const List<String> supportedVideoLookPresets = <String>[
    'original',
    'clear',
    'cinema',
    'vibe',
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

  Future<void> openPollComposer() async {
    final existing = pollData.value;
    final questionCtrl = TextEditingController(
      text: existing?['question']?.toString() ?? '',
    );
    final optionCtrls = <TextEditingController>[];
    if (existing != null && existing['options'] is List) {
      final opts = existing['options'] as List;
      for (final o in opts) {
        optionCtrls.add(
          TextEditingController(text: (o['text'] ?? '').toString()),
        );
      }
    }
    while (optionCtrls.length < 2) {
      optionCtrls.add(TextEditingController());
    }
    if (optionCtrls.length > 5) {
      optionCtrls.removeRange(5, optionCtrls.length);
    }

    InputDecoration fieldDecoration(String hint, {String? prefixText}) =>
        InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          counterText: '',
        );

    int selectedDurationHours =
        (existing?['durationHours'] is num) ? existing!['durationHours'] : 24;
    String durationLabel(int hours) {
      switch (hours) {
        case 6:
          return '6 sa';
        case 12:
          return '12 sa';
        case 24:
          return '1 g';
        case 72:
          return '3 g';
        case 168:
          return '7 g';
        default:
          return '1 g';
      }
    }

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Anket',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const Spacer(),
                    Text(
                      durationLabel(selectedDurationHours),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await Get.bottomSheet<int>(
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                const Text(
                                  'Zaman Seçenekleri',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  title: const Text('6 sa'),
                                  onTap: () => Get.back(result: 6),
                                ),
                                ListTile(
                                  title: const Text('12 sa'),
                                  onTap: () => Get.back(result: 12),
                                ),
                                ListTile(
                                  title: const Text('1 g'),
                                  onTap: () => Get.back(result: 24),
                                ),
                                ListTile(
                                  title: const Text('3 g'),
                                  onTap: () => Get.back(result: 72),
                                ),
                                ListTile(
                                  title: const Text('7 g'),
                                  onTap: () => Get.back(result: 168),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDurationHours = picked;
                          });
                        }
                      },
                      child: const Icon(
                        CupertinoIcons.clock,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Question field removed per request
                for (int i = 0; i < optionCtrls.length; i++) ...[
                  TextField(
                    controller: optionCtrls[i],
                    maxLines: 1,
                    maxLength: 25,
                    inputFormatters: [LengthLimitingTextInputFormatter(25)],
                    decoration: fieldDecoration(
                      'Seçenek ${i + 1}',
                      prefixText: '${String.fromCharCode(65 + i)}) ',
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                TextButton(
                  onPressed: optionCtrls.length >= 5
                      ? null
                      : () {
                          setState(() {
                            optionCtrls.add(TextEditingController());
                          });
                        },
                  child: const Text('+ Bir seçenek daha ekle'),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        pollData.value = null;
                        Get.back();
                      },
                      child: const Text('Kaldır'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        final options = optionCtrls
                            .map((c) => c.text.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();
                        if (options.length < 2) {
                          AppSnackbar('Hata', 'En az iki seçenek zorunlu.');
                          return;
                        }
                        pollData.value = {
                          'question': questionCtrl.text.trim(),
                          'durationHours': selectedDurationHours,
                          'options': options
                              .map((t) => {'text': t, 'votes': 0})
                              .toList(),
                        };
                        Get.back();
                      },
                      child: const Text('Oluştur'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> pickImage() async {
    if (selectedVideo.value != null || reusedVideoUrl.value.isNotEmpty) {
      UploadValidationService.showValidationError(
          'Video seçiliyken fotoğraf ekleyemezsiniz. En fazla 1 video seçilebilir.');
      return;
    }

    final postCreator = Get.find<PostCreatorController>();
    final isThread = postCreator.postList.length > 1;
    final existingCount = selectedImages.length;
    final maxImages = isThread ? 1 : UploadConstants.maxImagesPerPost;
    final existingReusedCount = reusedImageUrls.length;
    final remaining = maxImages - existingCount - existingReusedCount;
    if (remaining <= 0) {
      if (isThread) {
        UploadValidationService.showValidationError(
            'Dizi icinde her gonderide yalnizca 1 fotograf secilebilir.');
      }
      return;
    }

    final ctx = Get.context;
    if (ctx == null) return;
    final files = await AppImagePickerService.pickImages(
      ctx,
      maxAssets: remaining,
    );
    if (files.isEmpty) return;

    final currentImageCount = selectedImages.length + reusedImageUrls.length;
    final newImageCount = files.length;
    final totalCount = currentImageCount + newImageCount;

    if (totalCount > maxImages) {
      UploadValidationService.showValidationError(
          'Maksimum $maxImages fotograf ekleyebilirsiniz. '
          'Mevcut: $currentImageCount, Eklenmek istenen: $newImageCount');
      return;
    }

    for (int i = 0; i < files.length; i++) {
      final validation = await UploadValidationService.validateImage(files[i]);
      if (!validation.isValid) {
        UploadValidationService.showValidationError(
            'Fotoğraf ${i + 1}: ${validation.errorMessage}');
        return;
      }
    }

    final currentVideos =
        selectedVideo.value != null ? [selectedVideo.value!] : <File>[];
    final existingImages = selectedImages.toList();
    final allImages = [...existingImages, ...files];

    final totalSizeValidation =
        UploadValidationService.validateTotalPostSize(allImages, currentVideos);
    if (!totalSizeValidation.isValid) {
      UploadValidationService.showValidationError(
          totalSizeValidation.errorMessage!);
      return;
    }

    isProcessing.value = true;
    reusedImageUrls.clear();

    selectedImages.addAll(files);
    _enforceImageCap();

    // Show compression progress
    // AppSnackbar(
    //   'İşleniyor...',
    //   '${files.length} fotoğraf sıkıştırılıyor...',
    //   backgroundColor: Colors.blue.withValues(alpha: 0.8),
    // );

    try {
      // Compress images efficiently
      final network = Get.find<NetworkAwarenessService>();
      final optimalQuality = network.getOptimalCompressionQuality();
      final compressionResults = await MediaCompressionService.compressImages(
        imageFiles: files,
        quality: optimalQuality,
        onProgress: (current, total) {
          // Could add progress indicator here
        },
      );

      // Validate total size after compression (centralized)
      int newCompressedTotal = 0;
      for (final r in compressionResults) {
        newCompressedTotal += r.compressedSize;
      }
      int existingCompressed = 0;
      for (final b in croppedImages) {
        if (b != null) existingCompressed += b.length;
      }
      int currentVideo = 0;
      if (selectedVideo.value != null) {
        currentVideo = await selectedVideo.value!.length();
      }
      final validation = UploadValidationService.validateCompressedTotals(
        imagesBytes: newCompressedTotal,
        videoBytes: currentVideo,
        existingCompressedBytes: existingCompressed,
      );
      if (!validation.isValid) {
        UploadValidationService.showValidationError(validation.errorMessage!);
        isProcessing.value = false;
        return;
      }

      // Add compressed data
      for (final result in compressionResults) {
        croppedImages.add(result.compressedData);
      }
      _enforceImageCap();

      // Calculate total savings
      final totalOriginal =
          compressionResults.fold(0, (sum, r) => sum + r.originalSize);
      final totalCompressed =
          compressionResults.fold(0, (sum, r) => sum + r.compressedSize);
      final savingsPercent =
          ((1 - (totalCompressed / totalOriginal)) * 100).toStringAsFixed(1);

      if (kDebugMode) {
        debugPrint('[Creator] Images added: count=${compressionResults.length} '
            'originalTotal=${UploadConstants.formatBytes(totalOriginal)} -> '
            '${UploadConstants.formatBytes(totalCompressed)} (%$savingsPercent saved)');
      }

      FocusScope.of(Get.context!).unfocus();

      // AppSnackbar(
      //   'Başarılı!',
      //   '${files.length} fotoğraf eklendi. %$savingsPercent tasarruf sağlandı.',
      //   backgroundColor: Colors.green.withValues(alpha: 0.8),
      // );
    } catch (e) {
      // Fallback to original if compression fails
      for (var file in files) {
        final bytes = await file.readAsBytes();
        croppedImages.add(bytes);
      }
      _enforceImageCap();

      AppSnackbar(
        'Uyarı',
        'Fotoğraflar eklendi ancak sıkıştırma başarısız oldu.',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> pickImageFromCamera({required ImageSource source}) async {
    final picked = await picker.pickImage(
      source: source,
      imageQuality: UploadConstants.defaultImageQuality,
    );
    if (picked == null) return;

    final file = File(picked.path);
    await _processPickedImage(file);
  }

  Future<void> _processPickedImage(File file) async {
    // Validate image first
    isProcessing.value = true;
    final validation = await UploadValidationService.validateImage(file);
    if (!validation.isValid) {
      UploadValidationService.showValidationError(validation.errorMessage!);
      isProcessing.value = false;
      return;
    }

    // Clear existing media
    gif.value = '';
    await _releaseVideoController();
    selectedVideo.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    reusedImageUrls.clear();
    videoLookPreset.value = 'original';
    isPlaying.value = false;
    hasVideo.value = false;
    hasVideo.refresh();

    // Compress and add image
    try {
      selectedImages
        ..clear()
        ..add(file);
      croppedImages.clear();
      _enforceImageCap();

      // AppSnackbar(
      //   'İşleniyor...',
      //   'Fotoğraf sıkıştırılıyor...',
      //   backgroundColor: Colors.blue.withValues(alpha: 0.8),
      // );

      final network = Get.find<NetworkAwarenessService>();
      final compressionResult = await MediaCompressionService.compressImage(
        imageFile: file,
        targetQuality: network.getOptimalCompressionQuality(),
      );

      if (kDebugMode) {
        final saved = ((1 -
                    (compressionResult.compressedSize /
                        compressionResult.originalSize)) *
                100)
            .toStringAsFixed(1);
        debugPrint('[Creator] Camera image compressed: '
            'original=${UploadConstants.formatBytes(compressionResult.originalSize)} -> '
            '${compressionResult.format} ${UploadConstants.formatBytes(compressionResult.compressedSize)} '
            '(%$saved saved) size=${compressionResult.width}x${compressionResult.height}');
      }

      // Validate with existing compressed images and current video (centralized)
      int existingCompressed = 0;
      for (final b in croppedImages) {
        if (b != null) existingCompressed += b.length;
      }
      int currentVideo = 0;
      if (selectedVideo.value != null) {
        currentVideo = await selectedVideo.value!.length();
      }
      final validation2 = UploadValidationService.validateCompressedTotals(
        imagesBytes: compressionResult.compressedSize,
        videoBytes: currentVideo,
        existingCompressedBytes: existingCompressed,
      );
      if (!validation2.isValid) {
        UploadValidationService.showValidationError(validation2.errorMessage!);
        return;
      }

      croppedImages.add(compressionResult.compressedData);
      _enforceImageCap();

      AppSnackbar(
        'Başarılı!',
        'Fotoğraf eklendi. ${compressionResult.spaceSavedText}',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
      );
    } catch (e) {
      // Fallback to original
      final bytes = await file.readAsBytes();
      croppedImages.add(bytes);
      _enforceImageCap();

      AppSnackbar(
        'Uyarı',
        'Fotoğraf eklendi ancak sıkıştırma başarısız oldu.',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
      );
    } finally {
      isProcessing.value = false;
    }

    FocusScope.of(Get.context!).unfocus();
  }

  Future<void> pickVideo({required ImageSource source}) async {
    if (selectedVideo.value != null || reusedVideoUrl.value.isNotEmpty) {
      UploadValidationService.showValidationError(
          'En fazla ${UploadConstants.maxVideosPerPost} video seçebilirsiniz.');
      return;
    }

    File? file;
    if (source == ImageSource.gallery) {
      final ctx = Get.context;
      if (ctx == null) return;
      file = await AppImagePickerService.pickSingleVideo(ctx);
      if (file == null) return;
    } else {
      final picked = await picker.pickVideo(source: source);
      if (picked == null) return;
      file = File(picked.path);
    }

    await _processPickedVideo(file);
  }

  Future<void> _processPickedVideo(File file) async {
    // 1) Size and format validation first
    waitingVideo.value = false;
    isProcessing.value = true;

    final validation = await UploadValidationService.validateVideo(file);
    if (!validation.isValid) {
      isProcessing.value = false;
      UploadValidationService.showValidationError(validation.errorMessage!);
      return;
    }

    // 2) Check total post size including existing images
    final currentImages = selectedImages.toList();
    final totalSizeValidation =
        UploadValidationService.validateTotalPostSize(currentImages, [file]);
    if (!totalSizeValidation.isValid) {
      isProcessing.value = false;
      UploadValidationService.showValidationError(
          totalSizeValidation.errorMessage!);
      return;
    }

    // 3) Clear existing media (video replaces images and vice versa)
    gif.value = '';
    selectedImages.clear();
    croppedImages.clear();
    await _releaseVideoController();
    selectedVideo.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    reusedImageUrls.clear();
    isPlaying.value = false;
    hasVideo.value = false;
    hasVideo.refresh();
    selectedThumbnail.value = null;
    videoLookPreset.value = 'original';

    // 4) Setup video player immediately (no NSFW/compress here)
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    _bindVideoController(controller);

    selectedVideo.value = file;
    hasVideo.value = true;
    isPlaying.value = false;
    _listenVideo();
    hasVideo.refresh();

    isProcessing.value = false;

    if (kDebugMode) {
      final metadata = validation.metadata;
      final duration = metadata?['duration'] ?? 0;
      final size = UploadConstants.formatBytes(await file.length());
      debugPrint('[Creator] Video added: size=$size, duration=${duration}s');
    }
  }

  Future<void> setReusedVideoSource({
    required String videoUrl,
    required double aspectRatio,
    String thumbnail = '',
  }) async {
    final url = videoUrl.trim();
    if (url.isEmpty) return;

    waitingVideo.value = false;
    isProcessing.value = true;

    gif.value = '';
    selectedImages.clear();
    croppedImages.clear();
    reusedImageUrls.clear();
    await _releaseVideoController();
    selectedVideo.value = null;
    isPlaying.value = false;
    hasVideo.value = false;
    selectedThumbnail.value = null;

    reusedVideoUrl.value = url;
    reusedVideoThumbnail.value = thumbnail.trim();
    reusedVideoAspectRatio.value = aspectRatio > 0 ? aspectRatio : 0.0;
    reusedImageAspectRatio.value = 0.0;
    videoLookPreset.value = 'original';

    final uri = Uri.tryParse(url);
    if (uri == null) {
      isProcessing.value = false;
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    await controller.initialize();
    _bindVideoController(controller);
    hasVideo.value = true;
    isPlaying.value = false;
    _listenVideo();
    hasVideo.refresh();
    isProcessing.value = false;
  }

  Future<void> setReusedImageSources(
    List<String> imageUrls, {
    double aspectRatio = 0.0,
  }) async {
    final isThread = Get.find<PostCreatorController>().postList.length > 1;
    final uniqueUrls =
        imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (uniqueUrls.isEmpty) return;
    final limitedUrls = isThread ? [uniqueUrls.first] : uniqueUrls;

    waitingVideo.value = false;
    isProcessing.value = true;

    gif.value = '';
    await _releaseVideoController();
    selectedVideo.value = null;
    isPlaying.value = false;
    hasVideo.value = false;
    selectedThumbnail.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    videoLookPreset.value = 'original';
    reusedImageAspectRatio.value = aspectRatio > 0 ? aspectRatio : 0.0;
    selectedImages.clear();
    croppedImages.clear();
    reusedImageUrls.assignAll(limitedUrls);
    isProcessing.value = false;
  }

  void setVideoLookPreset(String preset) {
    if (!supportedVideoLookPresets.contains(preset)) return;
    videoLookPreset.value = preset;
  }

  Future<void> openCustomCameraCapture() async {
    final result = await Get.to<ChatCameraCaptureResult>(
      () => const ChatCameraCaptureView(),
      transition: Transition.fadeIn,
    );
    if (result == null) return;

    if (result.mode == ChatCameraMode.photo) {
      await _processPickedImage(result.file);
      return;
    }

    await _processPickedVideo(result.file);
  }

  void _enforceImageCap() {
    final max = UploadConstants.maxImagesPerPost;
    if (selectedImages.length > max) {
      selectedImages.assignAll(selectedImages.take(max).toList());
    }
    if (croppedImages.length > max) {
      croppedImages.assignAll(croppedImages.take(max).toList());
    }
  }

  /// Opens a bottom sheet to pick a custom thumbnail frame from the selected video
  Future<void> openThumbnailPicker() async {
    final vfile = selectedVideo.value;
    if (vfile == null) return;
    final ctx = Get.context;
    if (ctx == null) return;

    final duration = videoPlayerController?.value.duration ?? Duration.zero;
    final totalMs = duration.inMilliseconds.clamp(0, 60 * 60 * 1000);
    final RxDouble slider = ((totalMs / 3).toDouble()).obs; // selected timeMs
    final Rx<Uint8List?> preview = Rx<Uint8List?>(null);
    final RxBool loading = true.obs;
    // Static filmstrip (no scroll), one tile per second
    final int totalSec = ((totalMs / 1000).floor()).clamp(0, 3600);
    final int frameCount = (totalSec + 1).clamp(1, 3601);
    final List<int> stripTimes =
        List.generate(frameCount, (i) => (i * 1000).clamp(0, totalMs));
    final RxList<Uint8List?> stripThumbs =
        List<Uint8List?>.filled(frameCount, null).obs;
    final Map<int, bool> stripLoading = {};
    Timer? debounce;

    Future<void> generate(int timeMs) async {
      loading.value = true;
      try {
        final data = await vt.VideoThumbnail.thumbnailData(
          video: vfile.path,
          imageFormat: vt.ImageFormat.JPEG,
          timeMs: timeMs,
          maxWidth: 512,
          quality: 80,
        );
        preview.value = data;
      } catch (_) {
        preview.value = null;
      } finally {
        loading.value = false;
      }
    }

    // initial preview
    await generate(slider.value.toInt());
    // timers for continuous stepping
    Timer? holdTimerLeft;
    Timer? holdTimerRight;

    // Load a specific tile's thumbnail (evenly spaced across duration)
    Future<void> ensureStripThumb(int idx) async {
      if (idx < 0 || idx >= frameCount) return;
      if (stripThumbs[idx] != null || stripLoading[idx] == true) return;
      stripLoading[idx] = true;
      try {
        final data = await vt.VideoThumbnail.thumbnailData(
          video: vfile.path,
          imageFormat: vt.ImageFormat.JPEG,
          timeMs: stripTimes[idx],
          maxWidth: 160,
          quality: 70,
        );
        stripThumbs[idx] = data;
        stripThumbs.refresh();
      } catch (_) {
      } finally {
        stripLoading[idx] = false;
      }
    }

    void jumpToTimeMs(int timeMs) {
      final t = timeMs.clamp(0, totalMs);
      slider.value = t.toDouble();
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 120), () async {
        await generate(slider.value.toInt());
      });
      HapticFeedback.selectionClick();
    }

    await Get.bottomSheet(
      SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                ),
                12.ph,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                endIndent: 8,
                                color: Colors.grey,
                              )),
                              Text('Kapak Fotoğrafı Seç',
                                  style: TextStyles.bold16Black),
                              Expanded(
                                  child: Divider(
                                indent: 8,
                                color: Colors.grey,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (preview.value != null)
                          Image.memory(preview.value!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity),
                        if (loading.value)
                          const Center(child: CupertinoActivityIndicator()),
                        // step -1s
                        Positioned(
                          left: 8,
                          child: GestureDetector(
                            onTap: () {
                              final curSec = (slider.value / 1000).round();
                              final t = ((curSec - 1) * 1000).clamp(0, totalMs);
                              jumpToTimeMs(t.toInt());
                            },
                            onLongPressStart: (_) {
                              holdTimerLeft?.cancel();
                              holdTimerLeft = Timer.periodic(
                                  const Duration(milliseconds: 120), (timer) {
                                if (Get.isDialogOpen != true &&
                                    Get.isOverlaysOpen != true) {
                                  final curSec = (slider.value / 1000).round();
                                  if (curSec <= 0) {
                                    holdTimerLeft?.cancel();
                                    return;
                                  }
                                  final t =
                                      ((curSec - 1) * 1000).clamp(0, totalMs);
                                  jumpToTimeMs(t.toInt());
                                }
                              });
                            },
                            onLongPressEnd: (_) {
                              holdTimerLeft?.cancel();
                            },
                            onLongPressUp: () {
                              holdTimerLeft?.cancel();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.chevron_left,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        // step +1s
                        Positioned(
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              final curSec = (slider.value / 1000).round();
                              final t = ((curSec + 1) * 1000).clamp(0, totalMs);
                              jumpToTimeMs(t.toInt());
                            },
                            onLongPressStart: (_) {
                              holdTimerRight?.cancel();
                              holdTimerRight = Timer.periodic(
                                  const Duration(milliseconds: 120), (timer) {
                                final curSec = (slider.value / 1000).round();
                                if (curSec >= totalSec) {
                                  holdTimerRight?.cancel();
                                  return;
                                }
                                final t =
                                    ((curSec + 1) * 1000).clamp(0, totalMs);
                                jumpToTimeMs(t.toInt());
                              });
                            },
                            onLongPressEnd: (_) {
                              holdTimerRight?.cancel();
                            },
                            onLongPressUp: () {
                              holdTimerRight?.cancel();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.chevron_right,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Static, full-width filmstrip (no horizontal scroll)
                const SizedBox(height: 8),
                LayoutBuilder(builder: (context, constraints) {
                  final viewportW = constraints.maxWidth;
                  final double tileW = viewportW / frameCount;
                  // start generation of thumbnails
                  for (int i = 0; i < frameCount; i++) {
                    ensureStripThumb(i);
                  }
                  int dxToIndex(Offset local) {
                    final dx = local.dx.clamp(0.0, viewportW);
                    final idx = (dx / tileW).floor();
                    return idx.clamp(0, frameCount - 1);
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPressStart: (d) {
                      final idx = dxToIndex(d.localPosition);
                      jumpToTimeMs(stripTimes[idx]);
                    },
                    onLongPressMoveUpdate: (d) {
                      final idx = dxToIndex(d.localPosition);
                      jumpToTimeMs(stripTimes[idx]);
                    },
                    child: Row(
                      children: List.generate(frameCount, (i) {
                        return Expanded(
                          child: Obx(() {
                            final img = stripThumbs[i];
                            final selIdx = (totalMs == 0)
                                ? 0
                                : ((slider.value / totalMs) * (frameCount - 1))
                                    .round()
                                    .clamp(0, frameCount - 1);
                            final isSel = selIdx == i;
                            return GestureDetector(
                              onTap: () => jumpToTimeMs(stripTimes[i]),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                height: 74,
                                margin: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.primaryColor
                                        : Colors.transparent,
                                    width: isSel ? 3 : 0,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryColor
                                                .withValues(alpha: 0.40),
                                            blurRadius: 10,
                                            spreadRadius: 0.8,
                                          ),
                                        ]
                                      : [],
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: img == null
                                    ? const Center(
                                        child: CupertinoActivityIndicator())
                                    : Image.memory(img, fit: BoxFit.cover),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Get.back();
                        },
                        label: Text(
                          'Vazgeç',
                          style: TextStyles.medium15Black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: preview.value == null
                            ? null
                            : () {
                                selectedThumbnail.value = preview.value;
                                HapticFeedback.lightImpact();
                                Get.back();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.secondColor
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child:
                              Text('Kaydet', style: TextStyles.medium15white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> goToLocationMap() async {
    Get.to(() => LocationFinderView(
          submitButtonTitle: "Bu adresi kullan",
          backAdres: (v) {
            adres.value = v;
          },
          backLatLong: (_) {},
        ));
  }

  void _listenVideo() {
    videoPlayerController?.addListener(() {
      final controller = videoPlayerController!;
      final isNowPlaying = controller.value.isPlaying;
      final isEnded = controller.value.position >= controller.value.duration;

      if (isPlaying.value != isNowPlaying) {
        isPlaying.value = isNowPlaying;
      }

      if (isEnded && isPlaying.value) {
        isPlaying.value = false;
        controller.pause();
      }
    });
  }

  Future<void> playVideo() async {
    if (videoPlayerController != null && !isPlaying.value) {
      await AudioFocusCoordinator.instance.requestPreviewPlay(
        videoPlayerController!,
      );
      await videoPlayerController!.play();
      isPlaying.value = true;
    }
  }

  Future<void> pauseVideo() async {
    if (videoPlayerController != null && isPlaying.value) {
      await videoPlayerController!.pause();
      isPlaying.value = false;
    }
  }

  Future<void> forcePauseVideo() async {
    final controller = videoPlayerController;
    if (controller == null) return;
    await controller.pause();
    isPlaying.value = false;
  }

  Future<void> togglePlayPause() async {
    isPlaying.value ? pauseVideo() : playVideo();
  }

  void _bindVideoController(VideoPlayerController controller) {
    AudioFocusCoordinator.instance.registerPreviewPlayer(controller);
    rxVideoPlayerController.value = controller;
  }

  Future<void> _releaseVideoController() async {
    final controller = rxVideoPlayerController.value;
    if (controller == null) return;
    AudioFocusCoordinator.instance.unregisterPreviewPlayer(controller);
    await controller.pause();
    await controller.dispose();
    rxVideoPlayerController.value = null;
  }
}
