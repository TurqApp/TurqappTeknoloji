part of 'recommended_user_content_controller.dart';

class _RecommendedUserContentControllerState {
  late String userID;
  final isFollowing = false.obs;
  final followLoading = false.obs;
  final followRepository = ensureFollowRepository();
}

extension RecommendedUserContentControllerFieldsPart
    on RecommendedUserContentController {
  String get userID => _state.userID;
  set userID(String value) => _state.userID = value;
  RxBool get isFollowing => _state.isFollowing;
  RxBool get followLoading => _state.followLoading;
  FollowRepository get _followRepository => _state.followRepository;
}
