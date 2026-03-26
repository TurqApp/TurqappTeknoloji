part of 'notify_reader_controller.dart';

class NotifyReaderController extends GetxController {
  static NotifyReaderController ensure({String? tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(NotifyReaderController(), tag: tag);
  }

  static NotifyReaderController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<NotifyReaderController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<NotifyReaderController>(tag: tag);
  }

  final NotifyLookupRepository _lookupRepository =
      ensureNotifyLookupRepository();
  final RxString lastOpenedNotificationId = ''.obs;
  final RxString lastOpenedNotificationType = ''.obs;
  final RxString lastOpenedRouteKind = ''.obs;
  final RxString lastOpenedTargetId = ''.obs;
  static const _commentType = kNotificationPostTypeCommentLower;
  static const _profileTypes = {'follow', 'user'};
  static const _tutoringTypes = {'tutoring_application', 'tutoring_status'};
  static const _chatTypes = {'message', 'chat'};
  static const _marketTypes = {'market_offer', 'market_offer_status'};

  Future<void> openNotification(
    NotificationModel model, {
    bool returnToNavbarOnClose = true,
  }) =>
      _NotifyReaderControllerRuntimeX(this).openNotification(
        model,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
}
