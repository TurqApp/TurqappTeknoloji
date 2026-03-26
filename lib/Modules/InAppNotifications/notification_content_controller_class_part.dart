part of 'notification_content_controller.dart';

class NotificationContentController extends GetxController {
  static const String _userType = kNotificationPostTypeUserLower;
  static const String _commentType = kNotificationPostTypeCommentLower;
  static const String _chatType = kNotificationPostTypeChatLower;
  static const String _jobApplicationType =
      kNotificationPostTypeJobApplicationLower;
  static const String _tutoringApplicationType =
      kNotificationPostTypeTutoringApplicationLower;

  final _state = _NotificationContentControllerState();

  NotificationContentController({
    required String userID,
    required NotificationModel notification,
  }) {
    _state.userID = userID;
    _state.notification = notification;
  }

  @override
  void onInit() {
    super.onInit();
    _handleNotificationContentInit(this);
  }
}
