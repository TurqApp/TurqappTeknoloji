part of 'unread_messages_controller_library.dart';

UnreadMessagesController ensureUnreadMessagesController() =>
    maybeFindUnreadMessagesController() ?? Get.put(UnreadMessagesController());

UnreadMessagesController? maybeFindUnreadMessagesController() =>
    Get.isRegistered<UnreadMessagesController>()
        ? Get.find<UnreadMessagesController>()
        : null;
