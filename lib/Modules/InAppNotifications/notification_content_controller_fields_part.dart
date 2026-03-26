part of 'notification_content_controller.dart';

class _NotificationContentControllerState {
  late String userID;
  late NotificationModel notification;
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository followRepository = FollowRepository.ensure();
  final NotifyLookupRepository notifyLookupRepository =
      ensureNotifyLookupRepository();
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final following = false.obs;
  final followLoading = false.obs;
  final model = PostsModel.empty().obs;
  final targetHint = ''.obs;
}

extension NotificationContentControllerFieldsPart
    on NotificationContentController {
  String get userID => _state.userID;
  NotificationModel get notification => _state.notification;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  FollowRepository get _followRepository => _state.followRepository;
  NotifyLookupRepository get _notifyLookupRepository =>
      _state.notifyLookupRepository;
  RxString get avatarUrl => _state.avatarUrl;
  RxString get nickname => _state.nickname;
  RxBool get following => _state.following;
  RxBool get followLoading => _state.followLoading;
  Rx<PostsModel> get model => _state.model;
  RxString get targetHint => _state.targetHint;
}
