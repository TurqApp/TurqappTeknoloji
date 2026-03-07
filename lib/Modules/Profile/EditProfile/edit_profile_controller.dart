import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Core/BottomSheets/no_yes_alert.dart';

import '../../../Core/Services/optimized_nsfw_service.dart';

class EditProfileController extends GetxController {
  final CropController cropController = CropController();
  final ImagePicker picker = ImagePicker();

  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<Uint8List?> croppedImage = Rx<Uint8List?>(null); // preview için
  final RxBool isCropping =
      false.obs; // artık UI bağımsız, ancak geriye dönük korunuyor

  // 🎯 Using CurrentUserService for optimized user data access
  final userService = CurrentUserService.instance;
  @Deprecated('Use userService instead')
  final user = Get.find<FirebaseMyStore>(); // Backward compatibility

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // Varsayılan avatar URL'si ve yardımcı durum hesaplaması
  String get defaultAvatarUrl =>
      'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';

  bool get hasCustomProfilePhoto {
    final avatarUrl = userService.currentUser?.avatarUrl ?? '';
    return avatarUrl.isNotEmpty && avatarUrl != defaultAvatarUrl;
  }

  @override
  void onInit() {
    super.onInit();
    fetchAndSetUserData();
    // NSFW detector OptimizedNSFWService ile lazy initialize edilir
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  Future<void> fetchAndSetUserData() async {
    // 🎯 Using CurrentUserService - instant from cache!
    final currentUser = userService.currentUser;

    if (currentUser != null) {
      firstNameController.text = currentUser.firstName;
      lastNameController.text = currentUser.lastName;
    } else {
      // Fallback: Firebase'den çek (ilk açılış)
      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          firstNameController.text = data["firstName"] ?? "";
          lastNameController.text = data["lastName"] ?? "";
        }
      }
    }
  }

  Future<void> pickImage({required ImageSource source}) async {
    File? file;
    if (source == ImageSource.gallery) {
      final ctx = Get.context;
      if (ctx == null) return;
      file = await AppImagePickerService.pickSingleImage(ctx);
    } else {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      file = File(picked.path);
    }
    if (file == null) return;

    final r = await OptimizedNSFWService.checkImage(file);
    if (r.isNSFW) {
      selectedImage.value = null;
      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
    } else {
      // 1) Seçilen File’ı saklayın
      selectedImage.value = file;
      showCropDialog();

      print("Resim uygun, preview için atandı");
    }
  }

  void showCropDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        bool cropping = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Obx(() {
              if (selectedImage.value == null) return const SizedBox.shrink();
              return Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Crop(
                          image: selectedImage.value!.readAsBytesSync(),
                          controller: cropController,
                          aspectRatio: 1,
                          onCropped: (result) {
                            if (result is CropSuccess) {
                              croppedImage.value = result.croppedImage;
                              selectedImage.value = null;
                              setState(() => cropping = false);
                              Navigator.of(context).pop();
                            } else {
                              setState(() => cropping = false);
                            }
                          },
                          initialRectBuilder:
                              InitialRectBuilder.withSizeAndRatio(size: 0.8),
                          baseColor: Colors.white,
                          maskColor: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: cropping
                            ? Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const CupertinoActivityIndicator(
                                    color: Colors.white),
                              )
                            : TurqAppButton(
                                bgColor: Colors.black,
                                textColor: Colors.white,
                                text: "Kırp ve Kullan",
                                onTap: () {
                                  if (cropping) return;
                                  setState(() => cropping = true);
                                  cropController.crop();
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }

  Future<void> updateProfileInfo() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    String? newImageUrl;

    try {
      // Eğer yeni bir kırpılmış resim varsa, önce storage'a yükle
      if (croppedImage.value != null) {
        await _cleanupOldAvatarFiles(uid);
        final ts = DateTime.now().millisecondsSinceEpoch;
        newImageUrl = await WebpUploadService.uploadBytesAsWebp(
          storage: FirebaseStorage.instance,
          bytes: croppedImage.value!,
          storagePathWithoutExt: 'users/$uid/${uid}_${ts}_avatarUrl_thumb_150',
        );
        // Hard guarantee: persist avatar URL directly to users root doc.
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'avatarUrl': newImageUrl,
          'updatedDate': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }

      // 🎯 Using CurrentUserService.updateFields (cache + Firebase sync)
      await userService.updateFields({
        "firstName": firstNameController.text,
        "lastName": lastNameController.text,
        if (newImageUrl != null) "avatarUrl": newImageUrl,
      });

      // Backward compatibility: FirebaseMyStore otomatik güncellenir (wrapper)
      // user değişkeni artık gerekmiyor, CurrentUserService hallediyor!

      Get.back();
      AppSnackbar('Başarılı', 'Profil bilgilerin güncellendi!');
    } catch (e) {
      AppSnackbar('Hata', 'Güncelleme hatası: $e');
    } finally {
      isCropping.value = false; // olası açık state'leri toparla
    }
  }

  Future<void> removeProfilePhoto() async {
    await noYesAlert(
      title: 'Profil Fotoğrafını Kaldır',
      message:
          'Profil fotoğrafın kaldırılacak ve varsayılan avatar kullanılacak. Emin misin?',
      yesText: 'Kaldır',
      cancelText: 'İptal',
      onYesPressed: () async {
        try {
          // 🎯 Using CurrentUserService.updateFields
          await userService.updateFields({'avatarUrl': defaultAvatarUrl});

          // Yerel önizlemeleri temizle
          croppedImage.value = null;
          selectedImage.value = null;

          // FirebaseMyStore otomatik güncellenir (wrapper)
          AppSnackbar('Güncellendi', 'Profil fotoğrafın kaldırıldı.');
        } catch (e) {
          AppSnackbar(
              'Hata', 'Profil fotoğrafı kaldırılırken bir hata oluştu.');
        }
      },
    );
  }

  Future<void> _cleanupOldAvatarFiles(String uid) async {
    try {
      final folderRef = FirebaseStorage.instance.ref().child('users/$uid');
      final list = await folderRef.listAll();
      for (final item in list.items) {
        final name = item.name;
        if (name.contains('_avatarUrl') && name.endsWith('.webp')) {
          await item.delete();
        }
      }
    } catch (_) {
      // Best-effort cleanup; upload should continue even if deletion fails.
    }
  }
}
