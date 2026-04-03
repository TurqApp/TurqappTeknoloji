part of 'sinav_sorusu_hazirla_controller.dart';

extension SinavSorusuHazirlaControllerRuntimePart
    on SinavSorusuHazirlaController {
  void _handleInit() {
    getSorular();
  }

  Future<void> _loadQuestions() async {
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
    } catch (_) {
      AppSnackbar('common.error'.tr, 'practice.questions_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> _createQuestionDrafts() async {
    try {
      for (int i = 0; i < tumDersler.length; i++) {
        final soruSayisi = int.tryParse(derslerinSoruSayilari[i]) ?? 0;
        for (int j = 0; j < soruSayisi; j++) {
          await FirebaseFirestore.instance
              .collection('practiceExams')
              .doc(docID)
              .collection('Sorular')
              .doc(DateTime.now().microsecondsSinceEpoch.toString())
              .set({
            'id': j,
            'soru': '',
            'ders': tumDersler[i],
            'konu': '',
            'dogruCevap': 'A',
            'yanitlayanlar': [],
          });
          SetOptions(merge: true);
        }
      }
      await _practiceExamRepository.invalidateQuestionCaches(examId: docID);
      final questions = await _practiceExamRepository.fetchQuestions(
        docID,
        preferCache: false,
        forceRefresh: true,
      );
      if (questions.isNotEmpty) {
        list.assignAll(questions);
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tests.questions_create_failed'.tr);
    }
  }

  Future<void> _completeExam() async {
    try {
      await FirebaseFirestore.instance
          .collection('practiceExams')
          .doc(docID)
          .set({
        'taslak': false,
      }, SetOptions(merge: true));
      await ensurePracticeExamRepository().invalidateExamListingCaches(
        examId: docID,
      );
      complated();
      Get.back();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tests.complete_failed'.tr);
    }
  }
}
