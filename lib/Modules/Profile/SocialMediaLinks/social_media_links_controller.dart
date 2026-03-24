import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_branding.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'add_social_media_bottom_sheet.dart';

part 'social_media_links_controller_actions_part.dart';

class SocialMediaController extends GetxController {
  static SocialMediaController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SocialMediaController());
  }

  static SocialMediaController? maybeFind() {
    final isRegistered = Get.isRegistered<SocialMediaController>();
    if (!isRegistered) return null;
    return Get.find<SocialMediaController>();
  }

  final SocialMediaLinksRepository _linksRepository =
      SocialMediaLinksRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  RxList<SocialMediaModel> list = <SocialMediaModel>[].obs;

  var selected = "".obs;
  var textController = TextEditingController();
  var urlController = TextEditingController();
  var imageFile = Rxn<File>();
  var enableSave = false.obs;
  var isUploading = false.obs;
  var isLoading = false.obs;
  String get currentUid => CurrentUserService.instance.effectiveUserId;

  List<String> sosyal = List<String>.from(kSocialMediaEmbeddedKeys);

  bool isKnownEmbeddedKey(String key) => sosyal.contains(key);

  void _bindFormListeners() {
    selected.listen((_) => updateEnableSave());
    textController.addListener(updateEnableSave);
    urlController.addListener(updateEnableSave);
  }

  Future<void> _bootstrapDataImpl() async {
    if (currentUid.isEmpty) {
      isLoading.value = false;
      list.value = <SocialMediaModel>[];
      return;
    }
    final cached = await _linksRepository.getLinks(
      currentUid,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.value = List<SocialMediaModel>.from(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'profile:social_media:$currentUid',
        minInterval: SocialMediaController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      list.value = <SocialMediaModel>[];
      isLoading.value = false;
      return;
    }
    if (!silent) {
      isLoading.value = true;
    }
    try {
      list.value = List<SocialMediaModel>.from(
        await _linksRepository.getLinks(
          uid,
          preferCache: !forceRefresh,
          forceRefresh: forceRefresh,
        ),
      );
      SilentRefreshGate.markRefreshed('profile:social_media:$uid');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _bindFormListeners();
    unawaited(_bootstrapDataImpl());
  }
}
