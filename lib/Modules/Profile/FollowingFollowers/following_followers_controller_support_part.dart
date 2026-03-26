part of 'following_followers_controller.dart';

FollowingFollowersController _ensureFollowingFollowersController({
  required String userId,
  required int initialPage,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindFollowingFollowersController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    FollowingFollowersController(
      userId: userId,
      initialPage: initialPage,
    ),
    tag: tag,
    permanent: permanent,
  );
}

FollowingFollowersController? _maybeFindFollowingFollowersController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<FollowingFollowersController>(
    tag: tag,
  );
  if (!isRegistered) return null;
  return Get.find<FollowingFollowersController>(tag: tag);
}

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
