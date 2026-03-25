part of 'follower_controller.dart';

class _FollowerControllerState {
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final fullname = ''.obs;
  final isLoaded = false.obs;
  final isFollowed = false.obs;
  final followLoading = false.obs;
}

extension FollowerControllerFieldsPart on FollowerController {
  RxString get avatarUrl => _state.avatarUrl;
  RxString get nickname => _state.nickname;
  RxString get fullname => _state.fullname;
  RxBool get isLoaded => _state.isLoaded;
  RxBool get isFollowed => _state.isFollowed;
  RxBool get followLoading => _state.followLoading;
}
