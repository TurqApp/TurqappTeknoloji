part of 'unread_messages_controller_library.dart';

extension UnreadMessagesControllerSupportPart on UnreadMessagesController {
  void _recomputeTotalUnread() => totalUnreadCount.value = !_readStateReady
      ? 0
      : _conversationUnreadByUser.values.where((v) => v > 0).length;
}
