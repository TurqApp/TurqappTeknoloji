part of 'add_test_question_controller_library.dart';

extension AddTestQuestionControllerActionsPart on AddTestQuestionController {
  Future<void> yukle(File imageFile, int index) async {
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
          .doc(soruList[index].docID)
          .set({
        "img": downloadUrl,
        "id": soruList[index].id,
        "dogruCevap": soruList[index].dogruCevap,
        "yanitlayanlar": [],
        "max": 5,
      }, SetOptions(merge: true));

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

  void deleteQuestion(int index) {
    FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID)
        .collection("Sorular")
        .doc(soruList[index].docID)
        .delete();
    soruList.removeAt(index);
  }

  Future<void> publishTest() async {
    await FirebaseFirestore.instance.collection("Testler").doc(testID).set({
      "taslak": false,
    }, SetOptions(merge: true));
    Get.back();
  }
}
