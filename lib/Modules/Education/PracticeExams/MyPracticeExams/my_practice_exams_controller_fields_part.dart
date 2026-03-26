part of 'my_practice_exams_controller_library.dart';

class _MyPracticeExamsControllerState {
  final practiceExamRepository = ensurePracticeExamRepository();
  final exams = <SinavModel>[].obs;
  final isLoading = true.obs;
}

extension MyPracticeExamsControllerFieldsPart on MyPracticeExamsController {
  static final Expando<_MyPracticeExamsControllerState> _stateExpando =
      Expando<_MyPracticeExamsControllerState>('my_practice_exams_state');

  _MyPracticeExamsControllerState get _state =>
      _stateExpando[this] ??= _MyPracticeExamsControllerState();

  PracticeExamRepository get _practiceExamRepository =>
      _state.practiceExamRepository;
  RxList<SinavModel> get exams => _state.exams;
  RxBool get isLoading => _state.isLoading;
}
