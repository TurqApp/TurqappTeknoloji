part of 'unread_messages_controller.dart';

class UnreadMessagesController extends GetxController {
  final _state = _UnreadMessagesControllerState();

  @override
  void onInit() {
    super.onInit();
    if (_currentUid.isNotEmpty) {
      startListeners();
    }
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }
}
