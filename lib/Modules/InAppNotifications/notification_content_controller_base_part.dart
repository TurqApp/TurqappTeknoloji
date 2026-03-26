part of 'notification_content_controller.dart';

abstract class _NotificationContentControllerBase extends GetxController {
  final _state = _NotificationContentControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleNotificationContentInit(this as NotificationContentController);
  }
}
