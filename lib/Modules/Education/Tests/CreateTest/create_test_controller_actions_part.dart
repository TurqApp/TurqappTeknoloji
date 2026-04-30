part of 'create_test_controller.dart';

extension CreateTestControllerActionsPart on CreateTestController {
  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      imageFile.value = pickedFile;
      await analyzeImage();
    }
  }

  Future<void> analyzeImage() async {
    if (imageFile.value == null) return;
    try {
      final detector = await NsfwDetector.load(threshold: 0.3);
      final result = await detector.detectNSFWFromFile(imageFile.value!);
      print("NSFW detected: ${result?.isNsfw}");
      print("NSFW score: ${result?.score}");
      if (result == null || result.isNsfw) {
        imageFile.value = null;
      }
    } catch (e) {
      print("Error analyzing image: $e");
      imageFile.value = null;
    }
  }

  Future<void> yukle(File imageFile) async {
    if (!legacyTestsNetworkEnabled) return;
    try {
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        file: imageFile,
        storagePathWithoutExt:
            'Testler/${testID.value}/${DateTime.now().millisecondsSinceEpoch}',
      );
      await _testRepository.setTestImage(
        testId: testID.value.toString(),
        imageUrl: downloadUrl,
      );
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> deleteTest() async {
    if (!legacyTestsNetworkEnabled) return;
    await _testRepository.deleteTest(testID.value.toString());
    Get.back();
  }

  Future<void> saveTest(BuildContext context) async {
    if (!legacyTestsNetworkEnabled) return;
    if (!await TextModerationService.ensureAllowed([aciklama.text])) return;
    await _testRepository.updateTestDetails(
      testId: testID.value.toString(),
      data: {
        "aciklama": aciklama.text,
        "dersler": selectedDers.toList(),
        "paylasilabilir": paylasilabilir.value,
        "testTuru": testTuru.value,
      },
    );
    if (imageFile.value != null) {
      await yukle(imageFile.value!);
    }
    Get.back();
  }

  Future<void> prepareTest(BuildContext context) async {
    if (!legacyTestsNetworkEnabled) return;
    if (!await TextModerationService.ensureAllowed([aciklama.text])) return;
    await _testRepository.prepareDraftTest(
      testId: testID.value.toString(),
      data: {
        "aciklama": aciklama.text,
        "dersler": selectedDers.toList(),
        "favoriler": [],
        "paylasilabilir": paylasilabilir.value,
        "timeStamp": DateTime.now().millisecondsSinceEpoch.toString(),
        "userID": CurrentUserService.instance.effectiveUserId,
        "taslak": true,
        "testTuru": testTuru.value,
      },
    );
    if (imageFile.value != null) {
      await yukle(imageFile.value!);
    }
    Get.to(
      () => AddTestQuestion(
        soruList: sorularList,
        testID: testID.value.toString(),
        update: () => Get.back(),
        testTuru: testTuru.value,
      ),
    );
  }
}
