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
      await _practiceExamRepository.createQuestionDrafts(
        examId: docID,
        lessons: tumDersler,
        questionCounts: derslerinSoruSayilari
            .map((value) => int.tryParse(value) ?? 0)
            .toList(growable: false),
      );
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
      await _practiceExamRepository.publishPracticeExam(docID);
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
