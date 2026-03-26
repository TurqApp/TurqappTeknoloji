part of 'notification_content_controller.dart';

abstract class _NotificationContentControllerBase extends GetxController {
  _NotificationContentControllerBase({
    required String userID,
    required NotificationModel notification,
  }) : _state = _NotificationContentControllerState() {
    _state.userID = userID;
    _state.notification = notification;
  }

  final _NotificationContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleNotificationContentInit(this as NotificationContentController);
  }
}
