part of 'antreman_score_controller.dart';

class AntremanScoreController extends GetxController {
  static AntremanScoreController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AntremanScoreController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static AntremanScoreController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AntremanScoreController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AntremanScoreController>(tag: tag);
  }

  static List<Map<String, dynamic>>? _cachedLeaderboard;
  static DateTime? _cachedAt;
  static String? _cachedMonthKey;
  static const Duration _cacheTtl = Duration(minutes: 2);
  static const _excludedRozet = {'turkuaz'};

  final _state = _AntremanScoreControllerState();

  @override
  void onInit() {
    super.onInit();
    final hasWarmCache = _applyWarmCache();
    if (hasWarmCache) {
      unawaited(fetchLeaderboard(showLoader: false));
    } else {
      fetchLeaderboard();
    }
    getUserAntPoint();
  }
}
