part of 'sinav_hazirla_controller.dart';

extension SinavHazirlaControllerSubmissionPart on SinavHazirlaController {
  Future<void> pickImageFromGallery() async {
    isLoadingImage.value = true;
    try {
      final ctx = Get.context;
      if (ctx == null) return;
      final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
      if (pickedFile != null) {
        cover.value = pickedFile;
        await _analyzeImage();
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'tests.image_pick_failed'.tr);
    } finally {
      isLoadingImage.value = false;
    }
  }

  Future<void> _analyzeImage() async {
    if (cover.value == null) return;
    try {
      final detector = await NsfwDetector.load(threshold: 0.3);
      final result = await detector.detectNSFWFromFile(cover.value!);
      if (result == null || result.isNsfw) {
        AppSnackbar('common.error'.tr, 'tests.image_invalid'.tr);
        cover.value = null;
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'tests.image_analyze_failed'.tr);
      cover.value = null;
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime.value,
    );
    if (time != null) {
      selectedTime.value = time;
    }
  }

  Future<void> uploadImage(File imageFile, String docID) async {
    try {
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        file: imageFile,
        storagePathWithoutExt: 'practiceExams/$docID/cover',
      );
      await ensurePracticeExamRepository().updatePracticeExamCover(
        examId: docID,
        coverUrl: downloadUrl,
      );
    } catch (e) {
      AppSnackbar('common.error'.tr, 'tests.image_upload_failed_short'.tr);
    }
  }

  void setData(BuildContext context) async {
    isSaving.value = true;
    try {
      if (!await TextModerationService.ensureAllowed(<String?>[
        sinavIsmi.value.text,
        aciklama.value.text,
      ])) {
        return;
      }
      final combinedDateTime = DateTime(
        startDate.value.year,
        startDate.value.month,
        startDate.value.day,
        selectedTime.value.hour,
        selectedTime.value.minute,
      );

      await ensurePracticeExamRepository().savePracticeExam(
        examId: docID.value,
        data: {
          "sinavAdi": sinavIsmi.value.text,
          "sinavAciklama": aciklama.value.text,
          "timeStamp": combinedDateTime.millisecondsSinceEpoch,
          "dersler": currentDersler,
          "sinavTuru": sinavTuru.value,
          "kpssSecilenLisans": sinavTuru.value == _sinavTuruKpss
              ? _normalizeKpssLisans(kpssSecilenLisans.value)
              : sinavTuru.value,
          "soruSayilari": soruSayisiTextFields
              .map((controller) => controller.text)
              .toList(),
          "taslak": true,
          "public": public.value,
          "userID": CurrentUserService.instance.effectiveUserId,
          "bitisDk": sure.value,
          "bitis":
              combinedDateTime.millisecondsSinceEpoch + (sure.value * 60000),
        },
      );

      if (cover.value != null) {
        await uploadImage(cover.value!, docID.value);
      }

      await ensurePracticeExamRepository().invalidateExamListingCaches(
        examId: docID.value,
      );

      Get.to(
        () => SinavSorusuHazirla(
          docID: docID.value,
          sinavTuru: sinavTuru.value,
          tumDersler: currentDersler.toList(),
          derslerinSoruSayilari: soruSayisiTextFields
              .map((controller) => controller.text)
              .toList(),
          complated: () => Get.back(),
        ),
      );
    } catch (e) {
      AppSnackbar('common.error'.tr, 'tests.save_failed'.tr);
    } finally {
      isSaving.value = false;
    }
  }
}
