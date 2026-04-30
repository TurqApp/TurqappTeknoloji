part of 'create_book_controller.dart';

extension CreateBookControllerSubmissionPart on CreateBookController {
  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      imageFile.value = pickedFile;
      await _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (imageFile.value == null) return;
    try {
      final detector = await NsfwDetector.load(threshold: 0.3);
      final result = await detector.detectNSFWFromFile(imageFile.value!);
      if (result == null || result.isNsfw) {
        imageFile.value = null;
      }
    } catch (_) {
      imageFile.value = null;
    }
  }

  Future<void> setData(BuildContext context) async {
    showIndicator.value = true;
    try {
      if (!await TextModerationService.ensureAllowed(<String?>[
        baslikController.text,
        yayinEviController.text,
        ...list.map((item) => item.baslik),
      ])) {
        return;
      }

      await _bookletRepository.saveBooklet(docID, {
        'basimTarihi': basimTarihiController.text,
        'baslik': baslikController.text,
        'cover': existingBook?.cover ?? '',
        'dil': 'Türkçe',
        'sinavTuru': sinavTuru.value,
        'timeStamp':
            existingBook?.timeStamp ?? DateTime.now().millisecondsSinceEpoch,
        'yayinEvi': yayinEviController.text,
        'userID':
            existingBook?.userID ?? CurrentUserService.instance.effectiveUserId,
        'viewCount': existingBook?.viewCount ?? 0,
      });

      await _bookletRepository.replaceAnswerKeys(
        docID,
        list
            .map(
              (item) => <String, dynamic>{
                'baslik': item.baslik,
                'sira': item.sira,
                'dogruCevaplar': item.dogruCevaplar,
              },
            )
            .toList(growable: false),
      );

      if (imageFile.value != null) {
        await uploadImageToFirebaseStorage(imageFile.value!, context);
      } else {
        showIndicator.value = false;
        onBack?.call(true);
        Get.back();
      }
    } catch (_) {
      showIndicator.value = false;
      AppSnackbar(
        'common.error'.tr,
        'answer_key.cover_update_failed'.tr,
      );
    }
  }

  Future<void> uploadImageToFirebaseStorage(
    File imageFile,
    BuildContext context,
  ) async {
    try {
      final userId = CurrentUserService.instance.effectiveUserId;
      if (userId.isEmpty) {
        showIndicator.value = false;
        return;
      }

      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        showIndicator.value = false;
        return;
      }

      final resized = img.copyResize(
        originalImage,
        width: originalImage.width > 1400 ? 1400 : originalImage.width,
      );
      final resizedBytes = Uint8List.fromList(img.encodePng(resized));
      final webpData =
          await WebpUploadService.toWebpFromBytes(resizedBytes, quality: 85);
      if (webpData == null || webpData.isEmpty) {
        showIndicator.value = false;
        return;
      }

      final storagePathWithoutExt = 'books/$docID/cover';
      final storagePath = '$storagePathWithoutExt.webp';
      final downloadUrl = await WebpUploadService.uploadPreparedWebpBytes(
        bytes: webpData,
        storagePathWithoutExt: storagePathWithoutExt,
      );
      final cacheBustedUrl =
          '$downloadUrl${downloadUrl.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';

      await _bookletRepository.updateBookletCover(
        bookletId: docID,
        coverUrl: cacheBustedUrl,
        storagePath: storagePath,
      );

      AppSnackbar(
        'answer_key.cover_updated'.tr,
        'answer_key.cover_updated_body'.tr,
      );
      showIndicator.value = false;
      onBack?.call(true);
      Get.back();
    } catch (_) {
      showIndicator.value = false;
      AppSnackbar(
        'common.error'.tr,
        'answer_key.cover_update_failed'.tr,
      );
    }
  }
}
