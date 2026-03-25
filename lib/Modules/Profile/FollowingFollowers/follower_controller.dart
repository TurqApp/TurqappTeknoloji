import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'follower_controller_cache_part.dart';
part 'follower_controller_actions_part.dart';
part 'follower_controller_fields_part.dart';

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
