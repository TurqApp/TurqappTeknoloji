part of 'solve_test_controller.dart';

SolveTestController _ensureSolveTestController({
  required String testID,
  required Function showSucces,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindSolveTestController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SolveTestController(
      testID: testID,
      showSucces: showSucces,
    ),
    tag: tag,
    permanent: permanent,
  );
}

SolveTestController? _maybeFindSolveTestController({String? tag}) {
  final isRegistered = Get.isRegistered<SolveTestController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SolveTestController>(tag: tag);
}

class _SolveTestControllerState {
  _SolveTestControllerState({
    required this.testID,
    required this.showSucces,
  });

  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final TestRepository testRepository = TestRepository.ensure();
  final String testID;
  final Function showSucces;
  final RxList<TestReadinessModel> soruList = <TestReadinessModel>[].obs;
  final RxList<String> selections = <String>['A'].obs;
  final RxString cevap = ''.obs;
  final RxList<String> cevaplar = <String>[].obs;
  final Rx<Duration> elapsedTime = Rx<Duration>(Duration.zero);
  final RxString fullname = ''.obs;
  final RxBool isLoading = true.obs;
  late DateTime startTime;
  late Timer timer;
}

extension SolveTestControllerFieldsPart on SolveTestController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  TestRepository get _testRepository => _state.testRepository;
  String get testID => _state.testID;
  Function get showSucces => _state.showSucces;
  RxList<TestReadinessModel> get soruList => _state.soruList;
  RxList<String> get selections => _state.selections;
  RxString get cevap => _state.cevap;
  RxList<String> get cevaplar => _state.cevaplar;
  Rx<Duration> get elapsedTime => _state.elapsedTime;
  RxString get fullname => _state.fullname;
  RxBool get isLoading => _state.isLoading;
  DateTime get _startTime => _state.startTime;
  set _startTime(DateTime value) => _state.startTime = value;
  Timer get _timer => _state.timer;
  set _timer(Timer value) => _state.timer = value;
}
