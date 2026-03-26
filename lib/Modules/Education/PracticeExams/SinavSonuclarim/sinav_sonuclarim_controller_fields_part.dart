part of 'sinav_sonuclarim_controller.dart';

const Duration _sinavSonuclarimSilentRefreshInterval = Duration(minutes: 5);

class _SinavSonuclarimControllerState {
  final PracticeExamRepository practiceExamRepository =
      PracticeExamRepository.ensure();
  final RxList<SinavModel> list = <SinavModel>[].obs;
  final RxBool ustBar = true.obs;
  final RxBool isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  double previousOffset = 0.0;
}

extension SinavSonuclarimControllerFieldsPart on SinavSonuclarimController {
  PracticeExamRepository get _practiceExamRepository =>
      _state.practiceExamRepository;
  RxList<SinavModel> get list => _state.list;
  RxBool get ustBar => _state.ustBar;
  RxBool get isLoading => _state.isLoading;
  ScrollController get scrollController => _state.scrollController;
  double get _previousOffset => _state.previousOffset;
  set _previousOffset(double value) => _state.previousOffset = value;
}
