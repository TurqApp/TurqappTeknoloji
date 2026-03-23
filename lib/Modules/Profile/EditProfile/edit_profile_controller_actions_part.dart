part of 'edit_profile_controller.dart';

extension EditProfileControllerActionsPart on EditProfileController {
  Future<void> _pickImageImpl({required ImageSource source}) async {
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
      return;
    }

    selectedImage.value = file;
    showCropDialog();
    print("Resim uygun, preview için atandı");
  }

  void _showCropDialogImpl() {
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
                                  color: Colors.white,
                                ),
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

  Future<void> _updateProfileInfoImpl() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    String? newImageUrl;

    try {
      if (croppedImage.value != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final fileBase = '${uid}_${ts}_avatarUrl_thumb_150';
        newImageUrl = await WebpUploadService.uploadBytesAsWebp(
          storage: FirebaseStorage.instance,
          bytes: croppedImage.value!,
          storagePathWithoutExt: 'users/$uid/$fileBase',
        );
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
      isCropping.value = false;
    }
  }

  Future<void> _removeProfilePhotoImpl() async {
    await noYesAlert(
      title: 'edit_profile.remove_photo_title'.tr,
      message: 'edit_profile.remove_photo_message'.tr,
      yesText: 'common.remove'.tr,
      cancelText: 'common.cancel'.tr,
      onYesPressed: () async {
        try {
          final uid = _currentUid;
          if (uid.isEmpty) return;
          await userService.updateFields({'avatarUrl': defaultAvatarUrl});
          await _refreshAvatarNicknameSurfaces(uid);
          await AccountCenterService.ensure().refreshCurrentAccountMetadata();

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
    await UserProfileCacheService.invalidateIfRegistered(uid);
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
