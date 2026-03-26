part of 'follower_controller.dart';

class FollowerController extends GetxController {
  static FollowerController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      FollowerController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static FollowerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<FollowerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<FollowerController>(tag: tag);
  }

  final _state = _FollowerControllerState();
  static const Duration _followStateCacheTtl = Duration(seconds: 20);
  static const Duration _followStateStaleRetention = Duration(minutes: 3);
  static const int _maxFollowStateCacheEntries = 800;
  static const Duration _userCacheTtl = Duration(minutes: 5);
  static const Duration _userCacheStaleRetention = Duration(minutes: 20);
  static const int _maxUserCacheEntries = 400;
  static final Map<String, _FollowerUserCacheEntry> _userCacheById =
      <String, _FollowerUserCacheEntry>{};
  static final Map<String, _FollowStateCacheEntry> _followStateCacheByUser =
      <String, _FollowStateCacheEntry>{};
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Future<void> getData(String userID) =>
      _FollowerControllerCacheX(this).getData(userID);

  Future<void> followControl(String userID) =>
      _FollowerControllerCacheX(this).followControl(userID);
}
