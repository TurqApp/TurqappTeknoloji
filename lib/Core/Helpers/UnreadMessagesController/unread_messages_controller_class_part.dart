part of 'unread_messages_controller.dart';

class UnreadMessagesController extends GetxController {
  static UnreadMessagesController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UnreadMessagesController());
  }

  static UnreadMessagesController? maybeFind() {
    final isRegistered = Get.isRegistered<UnreadMessagesController>();
    if (!isRegistered) return null;
    return Get.find<UnreadMessagesController>();
  }

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
