part of 'rozet_content.dart';

class RozetController extends GetxController {
  static RozetController ensure(
    String userID, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      RozetController(userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static RozetController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<RozetController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<RozetController>(tag: tag);
  }

  final String userID;
  RozetController(this.userID);

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  Rx<Color> color = Colors.transparent.obs;
  static final Map<String, Color> _badgeCache = <String, Color>{};
  static final Map<String, int> _badgeCacheMs = <String, int>{};
  static const int _cacheTtlMs = 10 * 60 * 1000;
  static const int _staleRetentionMs = 30 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    _loadRozet();
  }

  Future<void> _loadRozet() async {
    _pruneStaleCache();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cachedColor = _badgeCache[userID];
    final cachedAt = _badgeCacheMs[userID] ?? 0;
    final isFresh = cachedColor != null &&
        cachedColor != Colors.transparent &&
        (nowMs - cachedAt) < _cacheTtlMs;
    if (isFresh) {
      color.value = cachedColor;
      return;
    }
    if (cachedColor != null) {
      color.value = cachedColor;
    }
    await _fetchRozetOnce();
  }

  void _pruneStaleCache() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final staleKeys = <String>[];
    for (final entry in _badgeCacheMs.entries) {
      if ((nowMs - entry.value) > _staleRetentionMs) {
        staleKeys.add(entry.key);
      }
    }
    for (final key in staleKeys) {
      _badgeCacheMs.remove(key);
      _badgeCache.remove(key);
    }
  }

  Future<void> _fetchRozetOnce() async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) {
        color.value = Colors.transparent;
        return;
      }
      final mapped = mapRozetToColor(summary.rozet);
      color.value = mapped;
      if (mapped == Colors.transparent) {
        _badgeCache.remove(userID);
        _badgeCacheMs.remove(userID);
      } else {
        _badgeCache[userID] = mapped;
        _badgeCacheMs[userID] = DateTime.now().millisecondsSinceEpoch;
      }
    } catch (_) {
      color.value = Colors.transparent;
    }
  }

  void updateUserID(String newUserID) {
    if (newUserID != userID) return;
    _loadRozet();
  }
}
