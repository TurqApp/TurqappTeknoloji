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
import 'package:turqappv2/Core/Services/post_caption_limits.dart';
import 'package:turqappv2/Core/Services/upload_validation_service.dart';
import 'package:turqappv2/Modules/EditPost/edit_post_model.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import '../../Core/LocationFinderView/location_finder_view.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Core/Services/video_compression_service.dart';
import '../../Core/Services/media_compression_service.dart';
import '../../Core/Services/webp_upload_service.dart';
import '../Agenda/agenda_controller.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';

part 'edit_post_controller_media_part.dart';
part 'edit_post_controller_actions_part.dart';

class EditPostController extends GetxController {
  static EditPostController ensure({
    required EditPostModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      EditPostController(model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static EditPostController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<EditPostController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<EditPostController>(tag: tag);
  }

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
      final netCtrl =
          HLSVideoAdapter(url: model.playbackUrl, autoPlay: false, loop: true);
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

  @override
  void onClose() {
    rxVideoController.value?.dispose();
    text.dispose();
    super.onClose();
  }
}
