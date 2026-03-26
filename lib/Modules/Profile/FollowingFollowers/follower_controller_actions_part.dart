part of 'follower_controller.dart';

extension FollowerControllerActionsPart on FollowerController {
  Future<void> follow(String otherUserID) async {
    if (followLoading.value) return;
    final wasFollowed = isFollowed.value;
    isFollowed.value = !wasFollowed;
    followLoading.value = true;
    late final FollowToggleOutcome outcome;
    try {
      outcome = await FollowService.toggleFollowFromLocalState(
        otherUserID,
        assumedFollowing: wasFollowed,
      );
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
        applyFollowingFollowersMutationToCaches(
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
