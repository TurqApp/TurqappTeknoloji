part of 'chat_listing_content_controller.dart';

class ChatListingContentController extends GetxController {
  static ChatListingContentController ensure({
    required String userID,
    required ChatListingModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ChatListingContentController(userID: userID, model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static ChatListingContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<ChatListingContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ChatListingContentController>(tag: tag);
  }

  final _ChatListingContentControllerState _state;

  ChatListingContentController({
    required String userID,
    required ChatListingModel model,
  }) : _state = _ChatListingContentControllerState(
          userID: userID,
          model: model,
        );

  @override
  void onInit() {
    super.onInit();
    _handleChatListingContentOnInit();
  }

  @override
  void onClose() {
    _handleChatListingContentOnClose();
    super.onClose();
  }
}
