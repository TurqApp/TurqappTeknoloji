part of 'following_followers_controller.dart';

class FollowingFollowersController extends GetxController {
  final _FollowingFollowersControllerState _state;

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
  }) : _state = _buildFollowingFollowersControllerState(
          userId: userId,
          initialPage: initialPage,
        );

  @override
  void onInit() {
    super.onInit();
    _handleFollowingFollowersControllerInit(this);
  }

  @override
  void onClose() {
    _handleFollowingFollowersControllerClose(this);
    super.onClose();
  }

  static void applyFollowMutationToCaches({
    required String currentUid,
    required String otherUserID,
    required bool nowFollowing,
  }) =>
      _applyFollowingFollowersControllerMutationToCaches(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );
}
