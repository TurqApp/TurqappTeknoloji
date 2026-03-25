part of 'notification_content_controller.dart';

class _NotificationContentControllerState {
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final following = false.obs;
  final followLoading = false.obs;
  final model = PostsModel.empty().obs;
  final targetHint = ''.obs;
}

extension NotificationContentControllerFieldsPart
    on NotificationContentController {
  RxString get avatarUrl => _state.avatarUrl;
  RxString get nickname => _state.nickname;
  RxBool get following => _state.following;
  RxBool get followLoading => _state.followLoading;
  Rx<PostsModel> get model => _state.model;
  RxString get targetHint => _state.targetHint;
}
