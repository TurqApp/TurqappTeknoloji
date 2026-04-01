part of 'in_app_notifications_controller.dart';

abstract class _InAppNotificationsControllerBase extends GetxController {
  final _state = _InAppNotificationsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleInAppNotificationsInit(this as InAppNotificationsController);
  }

  @override
  void onClose() {
    _handleInAppNotificationsClose(this as InAppNotificationsController);
    super.onClose();
  }
}
