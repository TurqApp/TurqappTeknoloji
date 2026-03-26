part of 'following_followers_controller.dart';

class FollowingFollowersController extends GetxController {
  final _state = _FollowingFollowersControllerState();

  @override
  void onClose() {
    _handleFollowingFollowersClose(this);
    super.onClose();
  }

  final String userId;

  static FollowingFollowersController ensure({
    required String userId,
    required int initialPage,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureFollowingFollowersController(
        userId: userId,
        initialPage: initialPage,
        tag: tag,
        permanent: permanent,
      );

  static FollowingFollowersController? maybeFind({String? tag}) =>
      _maybeFindFollowingFollowersController(tag: tag);

  FollowingFollowersController({
    required String userId,
    required int initialPage,
  }) : userId = userId.trim() {
    selection.value = initialPage;
  }

  @override
  void onInit() {
    super.onInit();
    _handleFollowingFollowersInit(this);
  }

  static void applyFollowMutationToCaches({
    required String currentUid,
    required String otherUserID,
    required bool nowFollowing,
  }) =>
      _applyFollowingFollowersMutationToCaches(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );
}
