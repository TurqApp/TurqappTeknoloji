part of 'unread_messages_controller.dart';

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
