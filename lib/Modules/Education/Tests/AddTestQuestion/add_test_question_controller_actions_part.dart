part of 'add_test_question_controller_library.dart';

extension AddTestQuestionControllerActionsPart on AddTestQuestionController {
  Future<void> yukle(File imageFile, int index) async {
    if (!legacyTestsNetworkEnabled) return;
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
        file: imageFile,
        storagePathWithoutExt:
            'Testler/$testID/${DateTime.now().millisecondsSinceEpoch}',
      );

      await _testRepository.saveQuestion(
        testId: testID,
        questionId: soruList[index].docID,
        data: {
          "img": downloadUrl,
          "id": soruList[index].id,
          "dogruCevap": soruList[index].dogruCevap,
          "yanitlayanlar": [],
          "max": 5,
        },
      );

      soruList[index] = TestReadinessModel(
        id: soruList[index].id,
        img: downloadUrl,
        max: soruList[index].max,
        dogruCevap: soruList[index].dogruCevap,
        docID: soruList[index].docID,
      );
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void addNewQuestion() {
    final docID = DateTime.now().millisecondsSinceEpoch.toInt();
    soruList.add(
      TestReadinessModel(
        id: docID,
        img: "",
        max: testTuru == _addQuestionMiddleSchoolType ? 4 : 5,
        dogruCevap: "",
        docID: docID.toString(),
      ),
    );
  }

  Future<void> deleteQuestion(int index) async {
    if (!legacyTestsNetworkEnabled) return;
    await _testRepository.deleteQuestion(
      testId: testID,
      questionId: soruList[index].docID,
    );
    soruList.removeAt(index);
  }

  Future<void> publishTest() async {
    if (!legacyTestsNetworkEnabled) return;
    await _testRepository.publishTest(testID);
    Get.back();
  }
}
