import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Modules/Social/ShareOfPost/thumbnail_data.dart';
import 'package:turqappv2/Modules/Social/ShareOfPost/video_cover_selector.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../../../Core/Services/optimized_nsfw_service.dart';

class ShareOfPostController extends GetxController {
  var selection = 5.obs;
  final CropController cropController = CropController();
  final globalLoader = Get.find<GlobalLoaderController>();
  final RxList<File> selectedImages = <File>[].obs;
  final RxList<Uint8List> croppedImages = <Uint8List>[].obs;
  final RxBool isCropping = false.obs;
  Rx<File?> selectedThumbnail = Rx<File?>(null);
  double selectedRatio = 3 / 4;
  Rx<DateTime?> izBirakDateTime = Rx<DateTime?>(null);

  Rx<File?> selectedVideo = Rx<File?>(null);
  VideoPlayerController? videoController;
  RxBool isVideoPlaying = false.obs;
  RxBool wait = false.obs;

  final thumbnails = <ThumbnailData>[].obs;
  late NsfwDetector nsfwDetector;

  TextEditingController textEditingController = TextEditingController();
  Rx<FocusNode> textFocus = FocusNode().obs;
  final scrollControler = ScrollController();
  final scrollControler2 = ScrollController();

  var comments = false.obs;
  var reShare = false.obs;

  int _currentCroppingIndex = 0;

  @override
  void onInit() {
    super.onInit();
    textFocus.value.addListener(() => textFocus.refresh());
    scrollControler2.addListener(() => textFocus.value.unfocus());
    _initializeNSFWDetector();
  }

  @override
  void onClose() {
    videoController?.dispose();
    selectedThumbnail.value = null;
    selectedVideo.value = null;
    super.onClose();
  }

  Future<void> pickImage({required ImageSource source}) async {
    File? file;
    if (source == ImageSource.gallery) {
      final ctx = Get.context;
      if (ctx == null) return;
      file = await AppImagePickerService.pickSingleImage(ctx);
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) file = File(picked.path);
    }
    if (file != null) {
      // NSFW kontrolü
      final r = await OptimizedNSFWService.checkImage(file);
      if (r.isNSFW) {
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }

      selectedImages.clear();
      croppedImages.clear();
      selectedThumbnail.value = null;
      selectedVideo.value = null;
      wait.value = false;
      videoController = null;
      thumbnails.clear();
      selectedImages.add(file);
      _currentCroppingIndex = 0;
      showCropBottomSheet();
    } else if (selectedImages.isNotEmpty) {
      selection.value = 5;
    }
  }

  Future<void> pickMultiImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final files = await AppImagePickerService.pickImages(ctx, maxAssets: 10);

    if (files.isNotEmpty) {
      // NSFW kontrolü (tüm görseller)
      for (final f in files) {
        final r = await OptimizedNSFWService.checkImage(f);
        if (r.isNSFW) {
          AppSnackbar(
            "Yükleme Başarısız!",
            "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
            backgroundColor: Colors.red.withValues(alpha: 0.7),
          );
          selection.value = 5;
          return;
        }
      }

      selectedImages.clear();
      croppedImages.clear();
      selectedThumbnail.value = null;
      selectedVideo.value = null;
      wait.value = false;
      izBirakDateTime.value = null;
      videoController = null;
      thumbnails.clear();

      for (final file in files) {
        selectedImages.add(file);

        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final cropSize =
              decoded.width < decoded.height ? decoded.width : decoded.height;
          final cropped = img.copyCrop(decoded,
              x: ((decoded.width - cropSize) / 2).round(),
              y: ((decoded.height - cropSize) / 2).round(),
              width: cropSize,
              height: cropSize);

          final croppedBytes = img.encodeJpg(cropped);
          croppedImages.add(Uint8List.fromList(croppedBytes));
        }
      }
      selection.value = 5;
    } else if (selectedImages.isNotEmpty) {
      selection.value = 5;
    }
  }

  Future<void> pickVideo() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final picked = await AppImagePickerService.pickSingleVideo(ctx);
    if (picked != null) {
      thumbnails.clear();
      selectedImages.clear();
      croppedImages.clear();
      izBirakDateTime.value = null;
      wait.value = true;
      selectedVideo.value = picked;
      videoController = VideoPlayerController.file(selectedVideo.value!)
        ..initialize().then((_) {
          selection.value = 2;
          _generateThumbnails();
        });
    }
  }

  Future<void> pickIzBirak() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final picked = await AppImagePickerService.pickSingleVideo(ctx);
    if (picked != null) {
      thumbnails.clear();
      selectedImages.clear();
      croppedImages.clear();
      wait.value = true;
      selectedVideo.value = picked;
      videoController = VideoPlayerController.file(selectedVideo.value!)
        ..initialize().then((_) {
          selection.value = 3;
          _generateThumbnails();
        });
    }
  }

  Future<void> _generateThumbnails() async {
    if (selectedVideo.value == null) return;

    final editor = VideoEditorBuilder(videoPath: selectedVideo.value!.path);
    final metadata = await editor.getVideoMetadata();
    final durationMs = metadata.duration;
    final tempDir = await getTemporaryDirectory();
    bool hasSensitiveContent = false;

    thumbnails.clear();

    for (int ms = 0; ms < durationMs; ms += 1000) {
      final thumbnailPath = path.join(tempDir.path, 'thumb_$ms.jpg');
      await editor.generateThumbnail(
        positionMs: ms,
        quality: 75,
        outputPath: thumbnailPath,
      );

      final thumbnailFile = File(thumbnailPath);
      final nsfwResult = await nsfwDetector.detectNSFWFromFile(thumbnailFile);
      final score = nsfwResult?.score ?? 0.0;

      String label = "";
      if (score > 0.7) {
        label = 'PORN';
      } else if (score > 0.6) {
        label = 'HENTAI';
      } else if (score > 0.3) {
        label = 'SEXY';
      }

      if (label == 'PORN' || label == 'HENTAI' || label == 'SEXY') {
        hasSensitiveContent = true;
      }

      thumbnails.add(ThumbnailData(
        file: thumbnailFile,
        nsfwLabel: label,
        score: score,
      ));
    }

    wait.value = false;

    if (hasSensitiveContent) {
      selectedVideo.value = null;
      videoController?.dispose();
      videoController = null;
      thumbnails.clear();
      selection.value = 5;

      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
    } else {
      selectedThumbnail.value = null;
      selectedThumbnail.value = thumbnails.first.file;
      selectedThumbnail.refresh();

      Get.bottomSheet(
        SizedBox(
          height: Get.height * 0.6, // maksimum %50
          child: VideoCoverSelector(
            listCount: thumbnails.length,
            list: thumbnails.toList(),
            onBackData: (val) {
              selectedThumbnail.value = val.file;
              selectedThumbnail.refresh();
            },
          ),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.white,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        enterBottomSheetDuration: Duration(milliseconds: 300),
        exitBottomSheetDuration: Duration(milliseconds: 200),
        settings: RouteSettings(name: 'VideoCoverBottomSheet'),
      );
    }
  }

  Future<void> _initializeNSFWDetector() async {
    nsfwDetector = await NsfwDetector.load(threshold: 0.3);
  }

  void showCropBottomSheet() {
    Get.bottomSheet(
      Obx(() {
        if (_currentCroppingIndex >= selectedImages.length) {
          return const SizedBox.shrink();
        }

        return Container(
          height: Get.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () {
                        cropController.aspectRatio = 3 / 4;
                        selectedRatio = 3 / 4;
                      },
                      child: const Text("3:4",
                          style: TextStyle(color: Colors.white))),
                  TextButton(
                      onPressed: () {
                        cropController.aspectRatio = 1 / 1;
                        selectedRatio = 1 / 1;
                      },
                      child: const Text("1:1",
                          style: TextStyle(color: Colors.white))),
                ],
              ),
              Expanded(
                child: Crop(
                  image:
                      selectedImages[_currentCroppingIndex].readAsBytesSync(),
                  controller: cropController,
                  onCropped: (result) {
                    if (result is CropSuccess) {
                      croppedImages.add(result.croppedImage);
                      _currentCroppingIndex++;
                      if (_currentCroppingIndex < selectedImages.length) {
                        cropController.image =
                            selectedImages[_currentCroppingIndex]
                                .readAsBytesSync();
                      } else {
                        selectedImages.clear();
                        Get.back();
                      }
                    }
                  },
                  initialRectBuilder:
                      InitialRectBuilder.withSizeAndRatio(size: 1),
                  baseColor: Colors.black,
                  maskColor: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    cropController.crop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Kırp ve Devam Et"),
                ),
              ),
            ],
          ),
        );
      }),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
    );
  }

  Future<void> setData() async {
    final docID = const Uuid().v4();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final userID = FirebaseAuth.instance.currentUser!.uid;

    // AspectRatio hesapla ve 4 haneye yuvarla
    double aspectRatio = 1.0;
    try {
      if (croppedImages.isNotEmpty && croppedImages.length == 1) {
        final decoded = img.decodeImage(croppedImages.first);
        if (decoded != null && decoded.height != 0) {
          aspectRatio = decoded.width / decoded.height;
        }
      } else if (selectedVideo.value != null &&
          videoController != null &&
          videoController!.value.isInitialized) {
        aspectRatio = videoController!.value.aspectRatio;
      }
    } catch (_) {}
    aspectRatio = double.parse(aspectRatio.toStringAsFixed(4));

    await FirebaseFirestore.instance.collection("Posts").doc(docID).set({
      "anaPaylasimPostID": docID,
      "arsiv": false,
      "deletedPost": false,
      "deletedPostTime": 0,
      "begeniler": [],
      "begenmeme": [],
      "goruntuleme": [],
      "hedefKitle": "Herkes",
      // Planlı ise timeStamp'i de aynı zamana ayarla
      "izBirakYayinTarihi": izBirakDateTime.value != null
          ? izBirakDateTime.value!.millisecondsSinceEpoch
          : nowMs,
      "kategori": [],
      "kayitEdenler": [],
      "konum": "",
      "mainUserID": userID,
      "metin": textEditingController.text,
      "muzik": "",
      "aspectRatio": aspectRatio,
      "tekrarPaylas": reShare.value,
      "thumbnailOfVideo": "",
      "timeStamp": izBirakDateTime.value != null
          ? izBirakDateTime.value!.millisecondsSinceEpoch
          : nowMs,
      "userID": userID,
      "video": "",
      "img": [],
      "yasKilidi": false,
      "yenidenPaylasilanKullanicilar": [],
      "yenidenPaylasilanPostlar": [],
      "yorumlar": comments.value,
      // Schema: always include original attribution fields
      "originalUserID": "",
      "originalPostID": "",
    });

    // Sayfadan çık (kullanıcıyı bekletme)
    Get.back();

    // Arka planda medya yükleme işlemini başlat
    Future.microtask(() {
      if (croppedImages.isNotEmpty) {
        uploadPhoto(docID);
      } else if (selectedVideo.value != null) {
        uploadVideoAndThumbnail(docID);
      }
    });
  }

  Future<void> uploadPhoto(String docID) async {
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;
    List<String> urls = [];
    final toplam = croppedImages.length;

    for (int i = 0; i < toplam; i++) {
      final rawData = croppedImages[i];
      final decoded = img.decodeImage(rawData);
      if (decoded == null) continue;

      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(decoded, quality: 50),
      );
      final webpBytes =
          await WebpUploadService.toWebpFromBytes(compressedBytes, quality: 85);
      if (webpBytes == null || webpBytes.isEmpty) continue;

      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.webp';
      final ref = storage.ref().child('Sosyal/$docID/$fileName');
      final uploadTask = ref.putData(
        webpBytes,
        SettableMetadata(
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );

      final snapshot = await uploadTask;
      final url = CdnUrlBuilder.toCdnUrl(await snapshot.ref.getDownloadURL());
      urls.add(url);

    }

    await firestore.collection('Sosyal').doc(docID).set({
      'img': urls,
    }, SetOptions(merge: true));
  }

  Future<void> uploadVideoAndThumbnail(String docID) async {
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;

    String? videoUrl;
    String? thumbnailUrl;

    final video = selectedVideo.value;
    final thumb = selectedThumbnail.value;

    if (video == null || thumb == null) return;

    // 1. Video Yükle
    final videoRef = storage.ref().child("Sosyal/$docID/video.mp4");
    final videoUploadTask = videoRef.putFile(
      video,
      SettableMetadata(
        contentType: 'video/mp4',
        cacheControl: 'public, max-age=31536000, immutable',
      ),
    );
    final videoSnap = await videoUploadTask;
    videoUrl = CdnUrlBuilder.toCdnUrl(await videoSnap.ref.getDownloadURL());

    // 2. Thumbnail Yükle
    final thumbBytes = await thumb.readAsBytes();
    final thumbDownloadUrl = await WebpUploadService.uploadBytesAsWebp(
      storage: storage,
      bytes: thumbBytes,
      storagePathWithoutExt: "Sosyal/$docID/thumbnail",
    );
    thumbnailUrl = CdnUrlBuilder.toCdnUrl(thumbDownloadUrl);

    // 3. Firestore'a kaydet (aspectRatio dahil)
    double ar = 1.0;
    try {
      if (videoController != null && videoController!.value.isInitialized) {
        ar = videoController!.value.aspectRatio;
      }
    } catch (_) {}
    ar = double.parse(ar.toStringAsFixed(4));
    await firestore.collection("Posts").doc(docID).set({
      "video": videoUrl,
      "thumbnailOfVideo": thumbnailUrl,
      "aspectRatio": ar,
    }, SetOptions(merge: true));
  }
}
