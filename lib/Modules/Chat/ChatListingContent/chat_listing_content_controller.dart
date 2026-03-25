import 'package:get/get.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';

part 'chat_listing_content_controller_runtime_part.dart';

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

  String userID;
  ChatListingModel model;
  var notReadCounter = 0.obs;
  RxList<MessageModel> lastMessage = <MessageModel>[].obs;
  Worker? _listWorker;

  ChatListingContentController({
    required this.userID,
    required this.model,
  });

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
