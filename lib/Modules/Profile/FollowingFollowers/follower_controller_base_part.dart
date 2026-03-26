part of 'follower_controller.dart';

abstract class _FollowerControllerBase extends GetxController {
  final _state = _FollowerControllerState();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = ensureFollowRepository();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;
}
