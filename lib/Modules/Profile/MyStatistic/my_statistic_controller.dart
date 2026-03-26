import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_stats_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_statistic_controller_facade_part.dart';
part 'my_statistic_controller_runtime_part.dart';

class MyStatisticController extends GetxController {
  static MyStatisticController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureMyStatisticController(tag: tag, permanent: permanent);

  static MyStatisticController? maybeFind({String? tag}) =>
      _maybeFindMyStatisticController(tag: tag);

  final ProfileStatsRepository _statsRepository =
      ProfileStatsRepository.ensure();
  final isLoading = true.obs;
  StreamSubscription<dynamic>? _userDocSub;

  // Core stats
  final totalPostViews = 0.obs;
  final totalStoryViews = 0.obs;
  final totalPosts = 0.obs;
  final followerCount = 0.obs;
  // 30-day stats
  final postViews30d = 0.obs;
  final posts30d = 0.obs;
  final stories30d = 0.obs;

  // Growth metrics (last 30 days)
  final followerGrowth30d = 0.obs;
  final followerGrowthPrev30d = 0.obs;
  final followerGrowthPct = 0.0.obs; // percent vs previous period

  // Post view rate vs followers (avg views per post / followers)
  final postViewRatePct = 0.0.obs;

  // Approx profile visits (story views in last 30d)
  final profileVisitsApprox = 0.obs;

  String get _currentUid => _myStatisticCurrentUid();

  // Controls
  @override
  void onInit() {
    super.onInit();
    _handleMyStatisticControllerInit(this);
  }

  @override
  Future<void> refresh() async {
    await _loadAll();
  }

  @override
  void onClose() {
    _handleMyStatisticControllerClose(this);
    super.onClose();
  }

  void _handleOnInit() => _MyStatisticControllerRuntimeX(this).handleOnInit();

  void _handleOnClose() => _MyStatisticControllerRuntimeX(this).handleOnClose();

  Future<void> _loadAll() => _MyStatisticControllerRuntimeX(this).loadAll();
}
