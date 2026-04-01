part of 'create_test_question_content_controller_library.dart';

extension CreateTestQuestionContentControllerActionsPart
    on CreateTestQuestionContentController {
  void setCorrectAnswer(String choice) {
    model.dogruCevap = choice;
    fastSetData(choice);
    update();
  }

  Future<void> fastSetData(String dogruCvp) {
    if (!legacyTestsNetworkEnabled) return Future<void>.value();
    return FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID)
        .collection("Sorular")
        .doc(model.docID)
        .set({"dogruCevap": dogruCvp}, SetOptions(merge: true));
  }

  Future<void> pickImageFromGallery() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      selectedImage.value = pickedFile;
      await yukle(pickedFile);
    }
  }

  Future<void> yukle(File imageFile) async {
    if (!legacyTestsNetworkEnabled) return;
    isLoading.value = true;
    try {
      final nsfw = await OptimizedNSFWService.checkImage(imageFile);
      if (nsfw.errorMessage != null) {
        AppSnackbar('common.error'.tr, 'tests.nsfw_check_failed'.tr);
        return;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('common.error'.tr, 'tests.nsfw_detected'.tr);
        return;
      }
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: imageFile,
        storagePathWithoutExt:
            'Testler/$testID/${DateTime.now().millisecondsSinceEpoch}',
      );

      await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID)
          .collection("Sorular")
          .doc(model.docID)
          .set({
        "img": downloadUrl,
        "id": model.id,
        "dogruCevap": model.dogruCevap,
        "yanitlayanlar": [],
        "max": model.max,
      }, SetOptions(merge: true));

      model.img = downloadUrl;
      selectedImage.value = null;
    } catch (e) {
      print("Error uploading image: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
