part of 'notification_content_controller_library.dart';

NotificationContentController ensureNotificationContentController({
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

NotificationContentController? maybeFindNotificationContentController({
  String? tag,
}) =>
    _maybeFindNotificationContentController(tag: tag);

NotificationContentController _ensureNotificationContentController({
  required String userID,
  required NotificationModel notification,
  String? tag,
  bool permanent = false,
}) =>
    _maybeFindNotificationContentController(tag: tag) ??
    Get.put(
      NotificationContentController(
        userID: userID,
        notification: notification,
      ),
      tag: tag,
      permanent: permanent,
    );

NotificationContentController? _maybeFindNotificationContentController({
  String? tag,
}) =>
    Get.isRegistered<NotificationContentController>(tag: tag)
        ? Get.find<NotificationContentController>(tag: tag)
        : null;

void _handleNotificationContentInit(NotificationContentController controller) {
  _NotificationContentControllerRuntimePart(controller).handleOnInit();
}

Future<void> _loadNotificationContentPostData(
  NotificationContentController controller,
  String docID,
) =>
    _NotificationContentControllerRuntimePart(controller).getPostData(docID);

Future<void> _toggleNotificationContentFollowStatus(
  NotificationContentController controller,
  String userID,
) =>
    _NotificationContentControllerActionsPart(controller)
        .toggleFollowStatus(userID);

extension NotificationContentControllerFacadePart
    on NotificationContentController {
  Future<void> getPostData(String docID) =>
      _loadNotificationContentPostData(this, docID);

  Future<void> toggleFollowStatus(String userID) =>
      _toggleNotificationContentFollowStatus(this, userID);
}
