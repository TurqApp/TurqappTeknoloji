import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'follower_controller_data_part.dart';

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

  var avatarUrl = "".obs;
  var nickname = "".obs;
  var fullname = "".obs;
  var isLoaded = false.obs;
  var isFollowed = false.obs;
  var followLoading = false.obs;
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

  Future<void> follow(String otherUserID) async {
    if (followLoading.value) return;
    final wasFollowed = isFollowed.value;
    isFollowed.value = !wasFollowed;
    followLoading.value = true;
    late final FollowToggleOutcome outcome;
    try {
      outcome = await FollowService.toggleFollow(otherUserID);
    } catch (_) {
      isFollowed.value = wasFollowed;
      isFollowed.refresh();
      AppSnackbar('common.error'.tr, 'following.update_failed'.tr);
      followLoading.value = false;
      return;
    }

    isFollowed.value = outcome.nowFollowing;
    isFollowed.refresh();

    final myUid = _currentUid;
    if (myUid.isNotEmpty) {
      try {
        FollowerController._followStateCacheByUser['$myUid:$otherUserID'] =
            _FollowStateCacheEntry(
          isFollowed: outcome.nowFollowing,
          cachedAt: DateTime.now(),
        );
        FollowingFollowersController.applyFollowMutationToCaches(
          currentUid: myUid,
          otherUserID: otherUserID,
          nowFollowing: outcome.nowFollowing,
        );
      } catch (_) {}
    }

    if (outcome.limitReached) {
      AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
    }

    followLoading.value = false;
  }
}

class _FollowerUserCacheEntry {
  final String avatarUrl;
  final String nickname;
  final String fullname;
  final DateTime cachedAt;

  const _FollowerUserCacheEntry({
    required this.avatarUrl,
    required this.nickname,
    required this.fullname,
    required this.cachedAt,
  });
}

class _FollowStateCacheEntry {
  final bool isFollowed;
  final DateTime cachedAt;

  const _FollowStateCacheEntry({
    required this.isFollowed,
    required this.cachedAt,
  });
}
