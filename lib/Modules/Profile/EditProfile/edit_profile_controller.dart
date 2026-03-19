import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
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
  final UserRepository _userRepository = UserRepository.ensure();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final RxString email = ''.obs;
  final RxString phoneNumber = ''.obs;
  StreamSubscription<Map<String, dynamic>?>? _userSub;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // Varsayılan avatar URL'si ve yardımcı durum hesaplaması
  String get defaultAvatarUrl => kDefaultAvatarUrl;

  bool get hasCustomProfilePhoto {
    final avatarUrl = userService.currentUser?.avatarUrl ?? '';
    return !isDefaultAvatarUrl(avatarUrl);
  }

  @override
  void onInit() {
    super.onInit();
    fetchAndSetUserData();
    _bindUserContactData();
    // NSFW detector OptimizedNSFWService ile lazy initialize edilir
  }

  @override
  void onClose() {
    _userSub?.cancel();
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  void _bindUserContactData() {
    _userSub?.cancel();
    _userSub = _userRepository.watchUserRaw(uid).listen((data) {
      if (data == null) return;
      final profile = (data["profile"] is Map)
          ? Map<String, dynamic>.from(data["profile"] as Map)
          : const <String, dynamic>{};
      final rawEmail =
          (data["email"] ?? profile["email"] ?? FirebaseAuth.instance.currentUser?.email ?? "")
              .toString()
              .trim();
      final rawPhone = (data["phoneNumber"] ?? profile["phoneNumber"] ?? "")
          .toString()
          .trim();
      email.value = rawEmail;
      phoneNumber.value = rawPhone;
    });
  }

  Future<void> fetchAndSetUserData() async {
    // 🎯 Using CurrentUserService - instant from cache!
    final currentUser = userService.currentUser;

    if (currentUser != null) {
      firstNameController.text = currentUser.firstName;
      lastNameController.text = currentUser.lastName;
    } else {
      // Fallback: Firebase'den çek (ilk açılış)
      final data = await _userRepository.getUserRaw(uid);
      if (data != null) {
        firstNameController.text = data["firstName"] ?? "";
        lastNameController.text = data["lastName"] ?? "";
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
        'edit_profile.upload_failed_title'.tr,
        'edit_profile.upload_failed_body'.tr,
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
                                text: 'edit_profile.crop_use'.tr,
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
        final ts = DateTime.now().millisecondsSinceEpoch;
        final fileBase = '${uid}_${ts}_avatarUrl_thumb_150';
        newImageUrl = await WebpUploadService.uploadBytesAsWebp(
          storage: FirebaseStorage.instance,
          bytes: croppedImage.value!,
          storagePathWithoutExt: 'users/$uid/$fileBase',
        );
        // Hard guarantee: persist avatar URL directly to users root doc.
        await _userRepository.updateUserFields(
          uid,
          {
            'avatarUrl': newImageUrl,
            'updatedDate': DateTime.now().millisecondsSinceEpoch,
          },
          mergeIntoCache: true,
        );
        await _cleanupOldAvatarFiles(uid, keepFileName: '$fileBase.webp');
      }

      // 🎯 Using CurrentUserService.updateFields (cache + Firebase sync)
      await userService.updateFields({
        "firstName": firstNameController.text,
        "lastName": lastNameController.text,
        if (newImageUrl != null) "avatarUrl": newImageUrl,
      });
      await _refreshAvatarNicknameSurfaces(uid);
      await AccountCenterService.ensure().refreshCurrentAccountMetadata();

      Get.back();
      AppSnackbar('common.success'.tr, 'edit_profile.update_success'.tr);
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'edit_profile.update_failed'.trParams({'error': '$e'}),
      );
    } finally {
      isCropping.value = false; // olası açık state'leri toparla
    }
  }

  Future<void> removeProfilePhoto() async {
    await noYesAlert(
      title: 'edit_profile.remove_photo_title'.tr,
      message: 'edit_profile.remove_photo_message'.tr,
      yesText: 'common.remove'.tr,
      cancelText: 'common.cancel'.tr,
      onYesPressed: () async {
        try {
          // 🎯 Using CurrentUserService.updateFields
          await userService.updateFields({'avatarUrl': defaultAvatarUrl});
          await _refreshAvatarNicknameSurfaces(uid);
          await AccountCenterService.ensure().refreshCurrentAccountMetadata();

          // Yerel önizlemeleri temizle
          croppedImage.value = null;
          selectedImage.value = null;

          AppSnackbar('common.update'.tr, 'edit_profile.photo_removed'.tr);
        } catch (e) {
          AppSnackbar(
            'common.error'.tr,
            'edit_profile.photo_remove_failed'.tr,
          );
        }
      },
    );
  }

  Future<void> _refreshAvatarNicknameSurfaces(String uid) async {
    if (Get.isRegistered<UserProfileCacheService>()) {
      await Get.find<UserProfileCacheService>().invalidateUser(uid);
    }
    PostContentController.invalidateUserProfileCache(uid);
    await userService.forceRefresh();
    await StoryRowController.refreshStoriesGlobally();
  }

  Future<void> _cleanupOldAvatarFiles(
    String uid, {
    String? keepFileName,
  }) async {
    try {
      final folderRef = FirebaseStorage.instance.ref().child('users/$uid');
      final list = await folderRef.listAll();
      for (final item in list.items) {
        final name = item.name;
        if (keepFileName != null && name == keepFileName) continue;
        if (name.contains('_avatarUrl') && name.endsWith('.webp')) {
          await item.delete();
        }
      }
    } catch (_) {
      // Best-effort cleanup; upload should continue even if deletion fails.
    }
  }
}
