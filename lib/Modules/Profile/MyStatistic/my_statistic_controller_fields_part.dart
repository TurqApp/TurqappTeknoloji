part of 'my_statistic_controller.dart';

class _MyStatisticControllerState {
  final ProfileStatsRepository statsRepository =
      ProfileStatsRepository.ensure();
  final RxBool isLoading = true.obs;
  StreamSubscription<dynamic>? userDocSub;
  final RxInt totalPostViews = 0.obs;
  final RxInt totalStoryViews = 0.obs;
  final RxInt totalPosts = 0.obs;
  final RxInt followerCount = 0.obs;
  final RxInt postViews30d = 0.obs;
  final RxInt posts30d = 0.obs;
  final RxInt stories30d = 0.obs;
  final RxInt followerGrowth30d = 0.obs;
  final RxInt followerGrowthPrev30d = 0.obs;
  final RxDouble followerGrowthPct = 0.0.obs;
  final RxDouble postViewRatePct = 0.0.obs;
  final RxInt profileVisitsApprox = 0.obs;
}

extension MyStatisticControllerFieldsPart on MyStatisticController {
  ProfileStatsRepository get _statsRepository => _state.statsRepository;
  RxBool get isLoading => _state.isLoading;
  StreamSubscription<dynamic>? get _userDocSub => _state.userDocSub;
  set _userDocSub(StreamSubscription<dynamic>? value) =>
      _state.userDocSub = value;
  RxInt get totalPostViews => _state.totalPostViews;
  RxInt get totalStoryViews => _state.totalStoryViews;
  RxInt get totalPosts => _state.totalPosts;
  RxInt get followerCount => _state.followerCount;
  RxInt get postViews30d => _state.postViews30d;
  RxInt get posts30d => _state.posts30d;
  RxInt get stories30d => _state.stories30d;
  RxInt get followerGrowth30d => _state.followerGrowth30d;
  RxInt get followerGrowthPrev30d => _state.followerGrowthPrev30d;
  RxDouble get followerGrowthPct => _state.followerGrowthPct;
  RxDouble get postViewRatePct => _state.postViewRatePct;
  RxInt get profileVisitsApprox => _state.profileVisitsApprox;
  String get _currentUid => _myStatisticCurrentUid();
}
