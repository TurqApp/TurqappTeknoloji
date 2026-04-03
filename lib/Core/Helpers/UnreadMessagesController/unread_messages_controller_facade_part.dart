part of 'unread_messages_controller_library.dart';

UnreadMessagesController ensureUnreadMessagesController() =>
    maybeFindUnreadMessagesController() ?? Get.put(UnreadMessagesController());

UnreadMessagesController ensureUnreadMessagesControllerStarted({
  bool force = false,
}) {
  final controller = ensureUnreadMessagesController();
  controller.startListeners(force: force);
  return controller;
}

UnreadMessagesController? maybeFindUnreadMessagesController() =>
    Get.isRegistered<UnreadMessagesController>()
        ? Get.find<UnreadMessagesController>()
        : null;
