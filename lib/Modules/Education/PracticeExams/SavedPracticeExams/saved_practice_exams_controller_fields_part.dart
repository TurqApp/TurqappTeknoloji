part of 'saved_practice_exams_controller.dart';

class _SavedPracticeExamsControllerState {
  final PracticeExamRepository practiceExamRepository =
      PracticeExamRepository.ensure();
  final UserSubcollectionRepository subcollectionRepository =
      ensureUserSubcollectionRepository();
  final RxList<String> savedExamIds = <String>[].obs;
  final RxList<SinavModel> savedExams = <SinavModel>[].obs;
  final RxBool isLoading = false.obs;
}

extension SavedPracticeExamsControllerFieldsPart
    on SavedPracticeExamsController {
  PracticeExamRepository get _practiceExamRepository =>
      _state.practiceExamRepository;
  UserSubcollectionRepository get _subcollectionRepository =>
      _state.subcollectionRepository;
  RxList<String> get savedExamIds => _state.savedExamIds;
  RxList<SinavModel> get savedExams => _state.savedExams;
  RxBool get isLoading => _state.isLoading;
}
