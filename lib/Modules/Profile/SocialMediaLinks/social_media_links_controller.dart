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

part 'social_media_links_controller_runtime_part.dart';

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

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _SocialMediaControllerRuntimeX(this).getData(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> pickImage(BuildContext context) =>
      _SocialMediaControllerRuntimeX(this).pickImage(context);

  void updateEnableSave() =>
      _SocialMediaControllerRuntimeX(this).updateEnableSave();

  void resetFields() => _SocialMediaControllerRuntimeX(this).resetFields();

  void showAddBottomSheet() =>
      _SocialMediaControllerRuntimeX(this).showAddBottomSheet();

  Future<void> updateAllSira() =>
      _SocialMediaControllerRuntimeX(this).updateAllSira();

  Future<void> updateItemOrder(int oldIndex, int newIndex) =>
      _SocialMediaControllerRuntimeX(this).updateItemOrder(oldIndex, newIndex);

  Future<String> uploadFileImage(File file, String docID) =>
      _SocialMediaControllerRuntimeX(this).uploadFileImage(file, docID);

  Future<void> deleteLink(String docId) =>
      _SocialMediaControllerRuntimeX(this).deleteLink(docId);

  Future<void> saveLink(SocialMediaModel model) =>
      _SocialMediaControllerRuntimeX(this).saveLink(model);

  @override
  void onInit() {
    super.onInit();
    _SocialMediaControllerRuntimeX(this).handleOnInit();
  }
}
