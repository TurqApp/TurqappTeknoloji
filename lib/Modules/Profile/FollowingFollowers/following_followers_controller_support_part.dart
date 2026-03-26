part of 'following_followers_controller.dart';

void _handleFollowingFollowersControllerInit(
  FollowingFollowersController controller,
) {
  _handleFollowingFollowersInit(controller);
}

void _handleFollowingFollowersControllerClose(
  FollowingFollowersController controller,
) {
  _handleFollowingFollowersClose(controller);
}

void _applyFollowingFollowersControllerMutationToCaches({
  required String currentUid,
  required String otherUserID,
  required bool nowFollowing,
}) {
  _applyFollowingFollowersMutationToCaches(
    currentUid: currentUid,
    otherUserID: otherUserID,
    nowFollowing: nowFollowing,
  );
}
