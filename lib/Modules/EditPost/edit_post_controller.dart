import 'dart:io';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Modules/EditPost/edit_post_model.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import '../../Core/LocationFinderView/location_finder_view.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Core/Services/video_compression_service.dart';
import '../../Core/Services/media_compression_service.dart';
import '../Agenda/agenda_controller.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';

class EditPostController extends GetxController {
  final EditPostModel model;
  final TextEditingController text = TextEditingController();
  final rxVideoController = Rxn<dynamic>();
  final isPlaying = false.obs;
  final imageUrls = <String>[].obs;
  final videoUrl = ''.obs;
  final adres = ''.obs;
  final yorum = false.obs;
  final thumbnail = ''.obs;
  final waitingVideo = false.obs;
  final bekle = false.obs;

  final picker = ImagePicker();
  final selectedImages = <File>[].obs;

  // Internal flags to track video edit intentions
  bool _newVideoSelected = false; // user picked a new local video
  bool _videoRemoved = false; // user removed existing video

  EditPostController({required this.model});

  @override
  void onInit() {
    super.onInit();

    // Initialize text field
    text.text = model.metin;
    yorum.value = model.yorum;
    // Initialize current location
    adres.value = model.konum;
    text.addListener(() {
      model.metin = text.text;
    });

    // Load existing video if any
    if (model.video.isNotEmpty) {
      waitingVideo.value = true;
      final netCtrl = HLSVideoAdapter(url: model.playbackUrl, autoPlay: false, loop: true);
      netCtrl.setLooping(true);
      netCtrl.addListener(() {
        isPlaying.value = netCtrl.value.isPlaying;
      });
      rxVideoController.value = netCtrl;
      // Keep the current network url for preview, but don't treat as a new selection
      videoUrl.value = model.playbackUrl;
      thumbnail.value = model.thumbnail;
      waitingVideo.value = false;
    }

    // Load existing image URLs
    imageUrls.assignAll(model.img);
  }

  void removeVideo() {
    rxVideoController.value?.dispose();
    rxVideoController.value = null;
    videoUrl.value = '';
    thumbnail.value = '';
    model.video = '';
    model.thumbnail = '';
    _newVideoSelected = false;
    _videoRemoved = true;
  }

  @override
  void onClose() {
    rxVideoController.value?.dispose();
    text.dispose();
    super.onClose();
  }

  Future<void> pickVideo({required ImageSource source}) async {
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

    // Clear images and previous video
    selectedImages.clear();
    removeVideo();
    isPlaying.value = false;
    waitingVideo.value = true;
    // Mark as a newly selected local video
    _newVideoSelected = true;
    _videoRemoved = false;

    // NSFW check (video)
    final nsfw = await OptimizedNSFWService.checkVideo(file);
    if (nsfw.isNSFW) {
      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      waitingVideo.value = false;
      return;
    }

    // Compress for network before generating thumbnail
    // AppSnackbar(
    //   'İşleniyor...',
    //   'Video sıkıştırılıyor...',
    //   backgroundColor: Colors.blue.withValues(alpha: 0.8),
    // );
    double targetMbps = 5.0;
    try {
      final net = Get.find<NetworkAwarenessService>();
      targetMbps = net.settings.mobileTargetMbps;
    } catch (_) {}
    final compressed = await VideoCompressionService.compressForNetwork(file,
        targetMbps: targetMbps);

    // Generate thumbnail at first frame
    final tempDir = await getTemporaryDirectory();
    final thumbPath = p.join(
        tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg');
    await VideoEditorBuilder(videoPath: compressed.path)
        .generateThumbnail(positionMs: 0, quality: 80, outputPath: thumbPath);
    thumbnail.value = thumbPath;
    model.thumbnail = thumbPath;

    // Initialize video player
    waitingVideo.value = true;
    videoUrl.value = compressed.path;

    final fileCtrl = VideoPlayerController.file(compressed);
    await fileCtrl.initialize();
    fileCtrl.setLooping(true);
    fileCtrl.addListener(() {
      isPlaying.value = fileCtrl.value.isPlaying;
    });

    rxVideoController.value = fileCtrl;
    waitingVideo.value = false;
  }

  void removeImageUrl(int index) {
    if (index >= 0 && index < imageUrls.length) {
      imageUrls.removeAt(index);
    }
  }

  void removeSelectedImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  Future<void> pickImageGallery() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final files = await AppImagePickerService.pickImages(ctx, maxAssets: 10);
    if (files.isEmpty) return;

    isPlaying.value = false;

    // 4) NSFW kontrolünü OptimizedNSFWService ile yap
    for (final f in files) {
      final r = await OptimizedNSFWService.checkImage(f);
      if (r.isNSFW) {
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        selectedImages.clear();
        imageUrls.clear();
        FocusScope.of(Get.context!).unfocus();
        return;
      }
    }

    imageUrls.clear();
    selectedImages
      ..clear()
      ..addAll(files);

    // 6) Klavyeyi kapat
    FocusScope.of(Get.context!).unfocus();
  }

  Future<void> pickImageCamera({required ImageSource source}) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      isPlaying.value = false;

      final file = File(picked.path);

      final r = await OptimizedNSFWService.checkImage(file);
      if (r.isNSFW) {
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        selectedImages.clear();
        imageUrls.clear();
      } else {
        imageUrls.clear();
        selectedImages
          ..clear()
          ..add(file);
      }

      FocusScope.of(Get.context!).unfocus();
    }
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

  Future<void> showCommentOptions() async {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
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
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                  SizedBox(width: 12),
                  Text(
                    "Yorumlar",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                ],
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = true;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Herkes yorum yapabilir.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: yorum.value
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = false;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Hiç kimse yorum yapamaz.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !yorum.value
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }

  Future<void> setData() async {
    try {
      bekle.value = true;
      final docRef =
          FirebaseFirestore.instance.collection('Posts').doc(model.docID);
      final storage = FirebaseStorage.instance;

      List<String> finalImageUrls = [];
      String? newVideoDownloadUrl;
      String? newThumbnailDownloadUrl;

      // --- 1) Resim yükleme ---
      if (selectedImages.isNotEmpty) {
        for (int i = 0; i < selectedImages.length; i++) {
          final file = selectedImages[i];
          try {
            final compressed = await MediaCompressionService.compressImage(
              imageFile: file,
              targetQuality: CompressionQuality.high,
            );
            final imgPath = 'Posts/${model.docID}/images/image_$i.webp';
            final task =
                await storage.ref(imgPath).putData(compressed.compressedData);
            finalImageUrls.add(
              CdnUrlBuilder.toCdnUrl(await task.ref.getDownloadURL()),
            );
          } catch (_) {
            // Fallback to original file upload as JPEG path
            final imgPath = 'Posts/${model.docID}/images/image_$i.jpg';
            final task = await storage.ref(imgPath).putFile(file);
            finalImageUrls.add(
              CdnUrlBuilder.toCdnUrl(await task.ref.getDownloadURL()),
            );
          }
        }
      } else {
        // Use the current on-screen url list (after any deletions), not original model
        finalImageUrls = List<String>.from(imageUrls);
      }

      // --- 2) Video yükleme + thumbnail üret ---
      // Decide based on flags instead of raw string presence
      if (_newVideoSelected && videoUrl.value.isNotEmpty) {
        final videoFile = File(videoUrl.value);

        // Thumbnail üret
        final tempDir = await getTemporaryDirectory();
        final localThumbPath = p.join(
            tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg');
        await VideoEditorBuilder(videoPath: videoFile.path).generateThumbnail(
            positionMs: 0, quality: 80, outputPath: localThumbPath);

        // Thumbnail'ı yükle
        final thumbKey =
            'Posts/${model.docID}/thumbnails/${p.basename(localThumbPath)}';
        final thumbTask =
            await storage.ref(thumbKey).putFile(File(localThumbPath));
        newThumbnailDownloadUrl = CdnUrlBuilder.toCdnUrl(
          await thumbTask.ref.getDownloadURL(),
        );

        // Videoyu yükle
        final vidKey =
            'Posts/${model.docID}/videos/${p.basename(videoFile.path)}';
        final vidTask = await storage.ref(vidKey).putFile(videoFile);
        newVideoDownloadUrl = CdnUrlBuilder.toCdnUrl(
          await vidTask.ref.getDownloadURL(),
        );
      }

      // --- 3) aspectRatio hesapla ---
      double aspectRatio;
      final contentIsVideoAfter =
          _newVideoSelected || (model.video.isNotEmpty && !_videoRemoved);
      if (contentIsVideoAfter) {
        final vpc = rxVideoController.value;
        if (vpc != null && vpc.value.isInitialized) {
          final sz = vpc.value.size;
          aspectRatio = (sz.height / sz.width > 4 / 3) ? 1.0 : 4 / 3;
        } else {
          aspectRatio = 4 / 3;
        }
      } else {
        if (finalImageUrls.length <= 1) {
          aspectRatio = 4 / 3;
        } else {
          aspectRatio = 1.0;
          // normalize to 4 decimals
          aspectRatio = double.parse(aspectRatio.toStringAsFixed(4));
        }
      }

      // --- 4) Firestore güncelleme ---
      final data = <String, dynamic>{
        'editTime': DateTime.now().millisecondsSinceEpoch,
        'metin': text.text,
        'konum': adres.value,
        'yorum': yorum.value,
        'aspectRatio': aspectRatio,
      };

      if (contentIsVideoAfter) {
        // If a new video is selected, push new urls; otherwise leave existing
        if (_newVideoSelected) {
          data['video'] = newVideoDownloadUrl ?? '';
          data['thumbnail'] = newThumbnailDownloadUrl ?? '';
        }
        data['img'] = [];
      } else {
        // No video after edit → ensure fields reflect images
        data['img'] = finalImageUrls;
        if (_videoRemoved || model.video.isNotEmpty) {
          data['video'] = '';
          data['thumbnail'] = '';
        }
      }

      await docRef.update(data);

      // --- 5) Hafif yerel güncelleme: mevcut post'u listelerde tazele ---
      try {
        final agendaCtrl = Get.find<AgendaController>();
        final idx =
            agendaCtrl.agendaList.indexWhere((e) => e.docID == model.docID);
        if (idx != -1) {
          final old = agendaCtrl.agendaList[idx];
          final updated = old.copyWith(
            editTime: DateTime.now().millisecondsSinceEpoch,
            metin: text.text,
            konum: adres.value,
            yorum: yorum.value,
            aspectRatio: aspectRatio,
            img: contentIsVideoAfter ? <String>[] : finalImageUrls,
            video: contentIsVideoAfter
                ? (_newVideoSelected
                    ? (newVideoDownloadUrl ?? old.video)
                    : old.video)
                : '',
            thumbnail: contentIsVideoAfter
                ? (_newVideoSelected
                    ? (newThumbnailDownloadUrl ?? old.thumbnail)
                    : old.thumbnail)
                : '',
          );
          agendaCtrl.agendaList[idx] = updated;
          agendaCtrl.agendaList.refresh();
        }
        // Update the AgendaContentController's edit time if present
        if (Get.isRegistered<AgendaContentController>(tag: model.docID)) {
          final contentCtrl =
              Get.find<AgendaContentController>(tag: model.docID);
          contentCtrl.editTime.value = DateTime.now().millisecondsSinceEpoch;
        }
      } catch (_) {}

      final profilecontroller = Get.find<ProfileController>();
      // Profil listelerini hafif senkron tut: en azından ana listeyi tazele
      profilecontroller.fetchPosts(isInitial: true);
      // Tip değişimi olabileceği için medyaya özel listeleri ayrı ayrı yenile
      if (contentIsVideoAfter) {
        profilecontroller.fetchVideos(isInitial: true);
      } else {
        profilecontroller.fetchPhotos(isInitial: true);
      }
    } catch (e) {
      print("setData error: $e");
    } finally {
      bekle.value = false;
      Get.back(result: model.docID);
    }
  }
}
