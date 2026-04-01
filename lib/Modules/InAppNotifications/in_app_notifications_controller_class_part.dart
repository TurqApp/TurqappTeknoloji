part of 'in_app_notifications_controller.dart';

class InAppNotificationsController extends _InAppNotificationsControllerBase {
  static InAppNotificationsController ensure({String? tag}) =>
      _ensureInAppNotificationsController(tag: tag);

  static InAppNotificationsController? maybeFind({String? tag}) =>
      _maybeFindInAppNotificationsController(tag: tag);
}
