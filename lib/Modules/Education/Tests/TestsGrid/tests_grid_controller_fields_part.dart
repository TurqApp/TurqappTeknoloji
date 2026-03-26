part of 'tests_grid_controller.dart';

class _TestsGridControllerState {
  final RxString fullName = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString nickname = ''.obs;
  final RxString secim = ''.obs;
  final RxInt totalYanit = 0.obs;
  final RxBool isFavorite = false.obs;
  final RxString appStore = ''.obs;
  final RxString googlePlay = ''.obs;
  final TestRepository testRepository = ensureTestRepository();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
}

extension TestsGridControllerFieldsPart on TestsGridController {
  RxString get fullName => _state.fullName;
  RxString get avatarUrl => _state.avatarUrl;
  RxString get nickname => _state.nickname;
  RxString get secim => _state.secim;
  RxInt get totalYanit => _state.totalYanit;
  RxBool get isFavorite => _state.isFavorite;
  RxString get appStore => _state.appStore;
  RxString get googlePlay => _state.googlePlay;
  TestRepository get _testRepository => _state.testRepository;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
}
