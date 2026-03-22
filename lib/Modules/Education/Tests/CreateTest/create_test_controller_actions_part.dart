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
    try {
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: imageFile,
        storagePathWithoutExt:
            'Testler/${testID.value}/${DateTime.now().millisecondsSinceEpoch}',
      );
      await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID.value.toString())
          .set({"img": downloadUrl}, SetOptions(merge: true));
      SetOptions(merge: true);
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> deleteTest() async {
    await FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .delete();
    Get.back();
  }

  Future<void> saveTest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .update({
      "aciklama": aciklama.text,
      "dersler": selectedDers.toList(),
      "paylasilabilir": paylasilabilir.value,
      "testTuru": testTuru.value,
    });
    if (imageFile.value != null) {
      await yukle(imageFile.value!);
    }
    Get.back();
  }

  Future<void> prepareTest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .set({
      "aciklama": aciklama.text,
      "dersler": selectedDers.toList(),
      "favoriler": [],
      "paylasilabilir": paylasilabilir.value,
      "timeStamp": DateTime.now().millisecondsSinceEpoch.toString(),
      "userID": CurrentUserService.instance.effectiveUserId,
      "taslak": true,
      "testTuru": testTuru.value,
    }, SetOptions(merge: true));
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
