import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'add_social_media_bottom_sheet.dart';

class SocialMediaController extends GetxController {
  RxList<SocialMediaModel> list = <SocialMediaModel>[].obs;

  var selected = "".obs;
  var textController = TextEditingController();
  var urlController = TextEditingController();
  var imageFile = Rxn<File>();
  var enableSave = false.obs;
  var isUploading = false.obs;

  List<String> sosyal = [
    "TurqApp",
    "instagram",
    "facebook",
    "whatsApp",
    "x",
    "youtube",
    "linkedin",
    "tiktok",
    "pinterest",
  ];

  String embeddedLogoAsset(String key) => "assets/icons/${key}_s.webp";

  bool isKnownEmbeddedKey(String key) => sosyal.contains(key);

  String normalizeEmbeddedKeyFromTitle(String title) {
    final normalized = title.trim().toLowerCase();
    switch (normalized) {
      case 'instagram':
        return 'instagram';
      case 'facebook':
        return 'facebook';
      case 'whatsapp':
        return 'whatsApp';
      case 'x':
        return 'x';
      case 'youtube':
        return 'youtube';
      case 'linkedin':
        return 'linkedin';
      case 'tiktok':
        return 'tiktok';
      case 'pinterest':
        return 'pinterest';
      case 'turqapp':
        return 'TurqApp';
      default:
        return '';
    }
  }

  @override
  void onInit() {
    super.onInit();
    getData();
    selected.listen((_) => updateEnableSave());
    textController.addListener(updateEnableSave);
    urlController.addListener(updateEnableSave);
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

  Future<void> getData() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("SosyalMedyaLinkleri")
        .get();
    List<SocialMediaModel> temp = [];
    for (var doc in snap.docs) {
      temp.add(SocialMediaModel.fromFirestore(doc));
    }

    list.value = temp;
  }

  void resetFields() {
    selected.value = "";
    textController.clear();
    urlController.clear();
    imageFile.value = null;
  }

  void showAddBottomSheet() {
    Get.bottomSheet(
      AddSocialMediaBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ).then((_) {
      getData();
    });
  }

  Future<void> updateAllSira() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < list.length; i++) {
      final model = list[i];
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("SosyalMedyaLinkleri")
          .doc(model.docID);

      batch.update(docRef, {"sira": i});
    }

    await batch.commit();
  }

  Future<void> updateItemOrder(int oldIndex, int newIndex) async {
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Firestore'da güncelle
    for (int i = 0; i < list.length; i++) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("SosyalMedyaLinkleri")
          .doc(list[i].docID)
          .update({"sira": i});
    }
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
      storagePathWithoutExt:
          "users/${FirebaseAuth.instance.currentUser!.uid}/social_links/$docID",
    );
  }
}
