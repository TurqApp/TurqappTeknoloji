part of 'sinav_sorusu_hazirla_controller.dart';

extension SinavSorusuHazirlaControllerDataPart on SinavSorusuHazirlaController {
  Future<void> _getSorularImpl() async {
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

  Future<void> _setListImpl() async {
    try {
      for (int i = 0; i < tumDersler.length; i++) {
        final soruSayisi = int.tryParse(derslerinSoruSayilari[i]) ?? 0;
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
}
