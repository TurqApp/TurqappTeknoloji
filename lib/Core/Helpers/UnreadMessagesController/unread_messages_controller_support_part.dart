part of 'unread_messages_controller_library.dart';

extension UnreadMessagesControllerSupportPart on UnreadMessagesController {
  void _recomputeTotalUnread() {
    if (!_readStateReady) {
      totalUnreadCount.value = 0;
      return;
    }
    totalUnreadCount.value =
        _conversationUnreadByUser.values.where((v) => v > 0).length;
  }
}
