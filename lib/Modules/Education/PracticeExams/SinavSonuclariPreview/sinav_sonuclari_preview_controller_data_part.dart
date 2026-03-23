part of 'sinav_sonuclari_preview_controller.dart';

extension SinavSonuclariPreviewControllerDataPart
    on SinavSonuclariPreviewController {
  Future<void> _getYanitlarImpl() async {
    isLoading.value = true;
    try {
      final snapshot = await _practiceExamRepository.fetchAnswers(
        model.docID,
        preferCache: true,
      );

      if (snapshot.isNotEmpty) {
        snapshot.sort(
          (a, b) => ((a['timeStamp'] ?? 0) as num)
              .compareTo((b['timeStamp'] ?? 0) as num),
        );
        final latest = snapshot.last;
        final yanitlarData = List<String>.from(latest['yanitlar'] ?? const []);
        final timeStampData = (latest["timeStamp"] ?? 0) as num;
        final yanitIDData = (latest["_docId"] ?? latest["id"] ?? "").toString();

        yanitlar.assignAll(yanitlarData);
        timeStamp.value = timeStampData;
        yanitID.value = yanitIDData;

        await getSorular();
      } else {
        isLoading.value = false;
        isInitialized.value = true;
      }
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.answers_load_failed'.tr);
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> _getSorularImpl() async {
    try {
      final questions = await _practiceExamRepository.fetchQuestions(
        model.docID,
        preferCache: true,
      );

      if (questions.isNotEmpty) {
        for (final question in questions) {
          if (!expandedCategories.containsKey(question.ders)) {
            expandedCategories[question.ders] = false;
          }
        }
        soruList.assignAll(questions);
        await getDersVeSonuclar(yanitID.value);
      }
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.questions_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> _getDersVeSonuclarImpl(String docID) async {
    try {
      final results = await _practiceExamRepository.fetchLessonResults(
        model.docID,
        docID,
        model.dersler,
      );
      dersVeSonuclar.assignAll(results);
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.lesson_results_load_failed'.tr);
    }
  }
}
