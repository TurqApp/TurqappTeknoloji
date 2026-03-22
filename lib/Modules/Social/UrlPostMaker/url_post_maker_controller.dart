import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:uuid/uuid.dart';

import '../../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../../Core/LocationFinderView/location_finder_view.dart';

part 'url_post_maker_controller_publish_part.dart';
part 'url_post_maker_controller_ui_part.dart';

class UrlPostMakerController extends GetxController {
  static UrlPostMakerController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      UrlPostMakerController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static UrlPostMakerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<UrlPostMakerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<UrlPostMakerController>(tag: tag);
  }

  TextEditingController textEditingController = TextEditingController();
  Rx<HLSVideoAdapter?> videoPlayerController = Rx<HLSVideoAdapter?>(null);
  RxBool isPlaying = false.obs;
  RxBool yorum = true.obs;
  RxBool isSharing = false.obs;
  RxString adres = ''.obs;

  String? originalUserID;
  String? originalPostID;

  @override
  void onClose() {
    videoPlayerController.value?.dispose();
    textEditingController.dispose();
    super.onClose();
  }
}
