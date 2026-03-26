part of 'unread_messages_controller.dart';

abstract class _UnreadMessagesControllerBase extends GetxController {
  final _state = _UnreadMessagesControllerState();
  UnreadMessagesController get _self => this as UnreadMessagesController;

  @override
  void onInit() {
    super.onInit();
    if (_self._currentUid.isNotEmpty) {
      _self.startListeners();
    }
  }

  @override
  void onClose() {
    _self._cancelAllSubscriptions();
    super.onClose();
  }
}
