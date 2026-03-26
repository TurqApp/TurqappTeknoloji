part of 'sinav_sorusu_hazirla_controller.dart';

extension SinavSorusuHazirlaControllerFacadePart
    on SinavSorusuHazirlaController {
  Future<void> getSorular() => _loadQuestions();

  Future<void> setList() => _createQuestionDrafts();

  Future<void> completeExam() => _completeExam();
}
