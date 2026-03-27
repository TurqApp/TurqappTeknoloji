part of 'notify_reader_controller.dart';

class NotifyReaderController extends _NotifyReaderControllerBase {
  Future<void> openNotification(
    NotificationModel model, {
    bool returnToNavbarOnClose = true,
  }) =>
      _NotifyReaderControllerRuntimeX(this).openNotification(
        model,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
}

NotifyReaderController ensureNotifyReaderController({String? tag}) =>
    maybeFindNotifyReaderController(tag: tag) ??
    Get.put(NotifyReaderController(), tag: tag);

NotifyReaderController? maybeFindNotifyReaderController({String? tag}) =>
    Get.isRegistered<NotifyReaderController>(tag: tag)
        ? Get.find<NotifyReaderController>(tag: tag)
        : null;
