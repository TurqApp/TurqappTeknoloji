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
      final hadFreshCache =
          !forceRefresh && await _linksRepository.hasFreshCacheEntry(uid);
      var items = await _linksRepository.getLinks(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (hadFreshCache && items.isEmpty) {
        items = await _linksRepository.getLinks(
          uid,
          preferCache: false,
          forceRefresh: true,
        );
      }
      list.value = List<SocialMediaModel>.from(items);
      SilentRefreshGate.markRefreshed('profile:social_media:$uid');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage(BuildContext context) async {
    final file = await AppImagePickerService.pickSingleImage(context);
    imageFile.value = file;
  }

  void updateEnableSave() {
    enableSave.value = textController.text.trim().isNotEmpty &&
        urlController.text.trim().isNotEmpty &&
        (selected.value.isNotEmpty || imageFile.value != null);
  }

  void resetFields() {
    selected.value = '';
    textController.clear();
    urlController.clear();
    imageFile.value = null;
  }

  void showAddBottomSheet() {
    Get.bottomSheet(
      AddSocialMediaBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ).then((_) {
      unawaited(getData(silent: true, forceRefresh: true));
    });
  }

  Future<void> updateAllSira() async {
    await _linksRepository.reorderLinks(
      currentUid,
      List<SocialMediaModel>.from(list),
    );
  }

  Future<void> updateItemOrder(int oldIndex, int newIndex) async {
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    await _linksRepository.reorderLinks(
      currentUid,
      List<SocialMediaModel>.from(list),
    );
  }

  Future<String> uploadFileImage(File file, String docID) async {
    isUploading.value = true;
    final nsfw = await OptimizedNSFWService.checkImage(file);
    if (nsfw.errorMessage != null) {
      throw Exception('NSFW görsel kontrolü başarısız');
    }
    if (nsfw.isNSFW) {
      throw Exception('Uygunsuz görsel tespit edildi');
    }
    return WebpUploadService.uploadFileAsWebp(
      storage: FirebaseStorage.instance,
      file: file,
      storagePathWithoutExt: 'users/$currentUid/social_links/$docID',
    );
  }

  Future<void> deleteLink(String docId) async {
    await _linksRepository.deleteLink(currentUid, docId);
  }

  Future<void> saveLink(SocialMediaModel model) async {
    await _linksRepository.saveLink(currentUid, model: model);
  }

  @override
  void onInit() {
    super.onInit();
    _bindFormListeners();
    unawaited(_bootstrapDataImpl());
  }
}
