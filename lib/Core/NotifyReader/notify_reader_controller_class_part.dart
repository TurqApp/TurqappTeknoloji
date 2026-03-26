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
