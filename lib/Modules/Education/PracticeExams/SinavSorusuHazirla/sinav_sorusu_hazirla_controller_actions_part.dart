part of 'sinav_sorusu_hazirla_controller.dart';

extension SinavSorusuHazirlaControllerActionsPart
    on SinavSorusuHazirlaController {
  Future<void> _completeExamImpl() async {
    try {
      await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(docID)
          .set({
        "taslak": false,
      }, SetOptions(merge: true));
      complated();
      Get.back();
    } catch (error) {
      AppSnackbar('common.error'.tr, 'tests.complete_failed'.tr);
    }
  }
}
