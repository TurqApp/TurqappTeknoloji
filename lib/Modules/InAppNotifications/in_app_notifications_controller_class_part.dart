part of 'in_app_notifications_controller.dart';

class InAppNotificationsController extends GetxController {
  static InAppNotificationsController ensure({String? tag}) =>
      _ensureInAppNotificationsController(tag: tag);

  static InAppNotificationsController? maybeFind({String? tag}) =>
      _maybeFindInAppNotificationsController(tag: tag);

  final _state = _InAppNotificationsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleInAppNotificationsInit(this);
  }

  void goToPage(int index) => _goToInAppNotificationsPage(this, index);

  int get unreadCount => _readInAppNotificationsUnreadCount(this);

  @override
  void onClose() {
    _handleInAppNotificationsClose(this);
    super.onClose();
  }
}
