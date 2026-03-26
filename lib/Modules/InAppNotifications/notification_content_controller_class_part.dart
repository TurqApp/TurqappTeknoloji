part of 'notification_content_controller.dart';

class NotificationContentController extends GetxController {
  static NotificationContentController ensure({
    required String userID,
    required NotificationModel notification,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureNotificationContentController(
        userID: userID,
        notification: notification,
        tag: tag,
        permanent: permanent,
      );

  static NotificationContentController? maybeFind({String? tag}) =>
      _maybeFindNotificationContentController(tag: tag);

  static const String _userType = kNotificationPostTypeUserLower;
  static const String _commentType = kNotificationPostTypeCommentLower;
  static const String _chatType = kNotificationPostTypeChatLower;
  static const String _jobApplicationType =
      kNotificationPostTypeJobApplicationLower;
  static const String _tutoringApplicationType =
      kNotificationPostTypeTutoringApplicationLower;

  String userID;
  final NotificationModel notification;
  final _state = _NotificationContentControllerState();

  NotificationContentController({
    required this.userID,
    required this.notification,
  });
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final NotifyLookupRepository _notifyLookupRepository =
      NotifyLookupRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleNotificationContentInit(this);
  }

  Future<void> getPostData(String docID) =>
      _loadNotificationContentPostData(this, docID);

  Future<void> toggleFollowStatus(String userID) =>
      _toggleNotificationContentFollowStatus(this, userID);
}
