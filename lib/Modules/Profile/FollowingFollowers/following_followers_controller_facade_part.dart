part of 'following_followers_controller.dart';

FollowingFollowersController _ensureFollowingFollowersController({
  required String userId,
  required int initialPage,
  String? tag,
  bool permanent = false,
}) =>
    _maybeFindFollowingFollowersController(tag: tag) ??
    Get.put(
      FollowingFollowersController(
        userId: userId,
        initialPage: initialPage,
      ),
      tag: tag,
      permanent: permanent,
    );

FollowingFollowersController? _maybeFindFollowingFollowersController({
  String? tag,
}) =>
    Get.isRegistered<FollowingFollowersController>(tag: tag)
        ? Get.find<FollowingFollowersController>(tag: tag)
        : null;

void _handleFollowingFollowersInit(FollowingFollowersController controller) {
  _FollowingFollowersControllerRuntimePart.onInit(controller);
}

void _handleFollowingFollowersClose(FollowingFollowersController controller) {
  _FollowingFollowersControllerRuntimePart.onClose(controller);
}

void _applyFollowingFollowersMutationToCaches({
  required String currentUid,
  required String otherUserID,
  required bool nowFollowing,
}) =>
    _applyFollowMutationToCachesImpl(
      currentUid: currentUid,
      otherUserID: otherUserID,
      nowFollowing: nowFollowing,
    );
