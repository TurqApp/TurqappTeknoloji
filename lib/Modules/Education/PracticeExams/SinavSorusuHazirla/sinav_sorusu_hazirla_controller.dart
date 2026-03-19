import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

class SinavSorusuHazirlaController extends GetxController {
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var list = <SoruModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  String docID;
  String sinavTuru;
  List<String> tumDersler;
  List<String> derslerinSoruSayilari;
  Function() complated;

  SinavSorusuHazirlaController({
    required this.docID,
    required this.sinavTuru,
    required this.tumDersler,
    required this.derslerinSoruSayilari,
    required this.complated,
  });

  @override
  void onInit() {
    super.onInit();
    getSorular();
  }

  Future<void> getSorular() async {
    isLoading.value = true;
    try {
      final questions = await _practiceExamRepository.fetchQuestions(
        docID,
        preferCache: true,
      );
      if (questions.isNotEmpty) {
        list.assignAll(questions);
      } else {
        await setList();
      }
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.questions_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> setList() async {
    try {
      for (int i = 0; i < tumDersler.length; i++) {
        int soruSayisi = int.tryParse(derslerinSoruSayilari[i]) ?? 0;
        for (int j = 0; j < soruSayisi; j++) {
          await FirebaseFirestore.instance
              .collection("practiceExams")
              .doc(docID)
              .collection("Sorular")
              .doc(DateTime.now().microsecondsSinceEpoch.toString())
              .set({
            "id": j,
            "soru": "",
            "ders": tumDersler[i],
            "konu": "",
            "dogruCevap": "A",
            "yanitlayanlar": [],
          });
          SetOptions(merge: true);
        }
      }
      await getSorular();
    } catch (error) {
      AppSnackbar('common.error'.tr, 'tests.questions_create_failed'.tr);
    }
  }

  void completeExam() async {
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
