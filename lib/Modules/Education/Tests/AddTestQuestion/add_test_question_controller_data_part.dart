part of 'add_test_question_controller.dart';

extension AddTestQuestionControllerDataPart on AddTestQuestionController {
  Future<void> getSorular() async {
    isLoading.value = true;
    try {
      final questions = await _testRepository.fetchQuestions(
        testID,
        preferCache: true,
      );
      soruList.assignAll(questions.reversed);
    } catch (e) {
      print("Error fetching questions: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
