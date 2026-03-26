part of 'following_followers_controller.dart';

abstract class _FollowingFollowersControllerBase extends GetxController {
  _FollowingFollowersControllerBase({
    required String userId,
    required int initialPage,
  }) : _state = _buildFollowingFollowersControllerState(
          userId: userId,
          initialPage: initialPage,
        );

  final _FollowingFollowersControllerState _state;
}
