part of 'job_creator_controller.dart';

extension JobCreatorControllerSubmissionPart on JobCreatorController {
  Future<void> pickImage({required ImageSource source}) async =>
      _pickImageInternal(source: source);

  Future<void> _pickImageInternal({required ImageSource source}) async {
    File? file;
    if (source == ImageSource.gallery) {
      final ctx = Get.context;
      if (ctx == null) return;
      file = await AppImagePickerService.pickSingleImage(ctx);
    } else {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) file = File(picked.path);
    }
    if (file == null) return;
    selectedImage.value = file;
    _showCropDialogInternal();
  }

  Future<void> showCropDialog() async => _showCropDialogInternal();

  Future<void> _showCropDialogInternal() async {
    Get.dialog(
      Obx(() {
        if (selectedImage.value == null) return SizedBox.shrink();

        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: Crop(
                  aspectRatio: 1,
                  image: selectedImage.value!.readAsBytesSync(),
                  controller: cropController,
                  onCropped: (result) {
                    if (result is CropSuccess) {
                      croppedImage.value = result.croppedImage;
                      selectedImage.value = null;
                      Get.back();
                    }
                  },
                  initialRectBuilder:
                      InitialRectBuilder.withSizeAndRatio(size: 0.8),
                  baseColor: Colors.black,
                  maskColor: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    cropController.crop();
                  },
                  child: Text('pasaj.job_finder.create.crop_use'.tr),
                ),
              ),
            ],
          ),
        );
      }),
      barrierDismissible: false,
    );
  }

  Future<void> uploadCroppedImageToFirebase(String docID) async =>
      _uploadCroppedImageToFirebaseInternal(docID);

  Future<void> _uploadCroppedImageToFirebaseInternal(String docID) async {
    final bytes = croppedImage.value;
    if (bytes == null) return;

    final tempDir = await Directory.systemTemp.createTemp('job_logo_');
    final tempFile = File('${tempDir.path}/logo_check.webp');
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      final nsfw = await OptimizedNSFWService.checkImage(tempFile);
      if (nsfw.errorMessage != null) {
        throw Exception('pasaj.job_finder.image_security_failed'.tr);
      }
      if (nsfw.isNSFW) {
        throw Exception('pasaj.job_finder.image_nsfw_detected'.tr);
      }

      final downloadUrl = await WebpUploadService.uploadBytesAsWebp(
        storage: FirebaseStorage.instance,
        bytes: bytes,
        storagePathWithoutExt: "isBul/$docID/logo",
      );

      await FirebaseFirestore.instance
          .collection("isBul")
          .doc(docID)
          .set({"logo": downloadUrl}, SetOptions(merge: true));
    } finally {
      try {
        if (await tempFile.exists()) await tempFile.delete();
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<void> setData() async => _setDataInternal();

  Future<void> _setDataInternal() async {
    final docID = existingJob?.docID ?? Uuid().v4();
    final loader = GlobalLoaderController.maybeFind(tag: loaderTag) ??
        GlobalLoaderController.ensure(tag: loaderTag, permanent: false);
    loader.isOn.value = true;
    try {
      final current = CurrentUserService.instance.currentUser;
      final nickname = (current?.nickname ?? '').trim();
      final fullName = [
        current?.firstName ?? '',
        current?.lastName ?? '',
      ].where((part) => part.trim().isNotEmpty).join(' ').trim();
      final displayName = fullName.isEmpty ? nickname : fullName;
      final avatarUrl = (current?.avatarUrl ?? '').trim();
      final rozet = (current?.rozet ?? '').trim();

      final jobData = <String, dynamic>{
        "about": about.text,
        "adres": adres.value,
        "avatarUrl": avatarUrl,
        "brand": brand.text,
        "calismaGunleri": selectedCalismaGunleri.toList(),
        "calismaSaatiBaslangic": calismaSaatiBaslangic.text.trim(),
        "calismaSaatiBitis": calismaSaatiBitis.text.trim(),
        "calismaTuru": selectedCalismaTuruList.toList(),
        "city": sehir.value,
        "displayName": displayName,
        "town": ilce.value,
        "ended": false,
        "isTanimi": isTanimi.text,
        "lat": lat.value,
        "long": long.value,
        "logo": existingJob?.logo ?? "",
        "maas1": maasOpen.value ? parseMoneyInput(maas1.text) : 0,
        "maas2": maasOpen.value ? parseMoneyInput(maas2.text) : 0,
        "meslek": meslek.value,
        "nickname": nickname,
        "authorAvatarUrl": avatarUrl,
        "authorDisplayName": displayName,
        "authorNickname": nickname,
        "userID": _currentUid,
        "rozet": rozet,
        "yanHaklar": selectedYanHaklar.toList(),
        "ilanBasligi": ilanBasligi.text,
        "basvuruSayisi": int.tryParse(basvuruSayisi.text) ?? 0,
        "pozisyonSayisi": int.tryParse(pozisyonSayisi.text) ?? 1,
      };

      if (existingJob != null) {
        jobData["timeStamp"] = DateTime.now().millisecondsSinceEpoch;
        await FirebaseFirestore.instance
            .collection("isBul")
            .doc(docID)
            .update(jobData);
      } else {
        jobData["timeStamp"] = DateTime.now().millisecondsSinceEpoch;
        jobData["viewCount"] = 0;
        jobData["applicationCount"] = 0;
        await FirebaseFirestore.instance
            .collection("isBul")
            .doc(docID)
            .set(jobData);
      }

      selection.value = 0;
      final shouldUploadLogo = croppedImage.value != null;
      loader.isOn.value = false;
      Get.back();
      if (shouldUploadLogo) {
        unawaited(_uploadLogoAfterClose(docID));
      }
    } finally {
      if (loader.isOn.value) {
        loader.isOn.value = false;
      }
    }
  }

  Future<void> _uploadLogoAfterClose(String docID) async {
    try {
      await uploadCroppedImageToFirebase(docID);
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
