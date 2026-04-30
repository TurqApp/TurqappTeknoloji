import 'package:get/get.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing.dart';

class ChatNavigationService {
  const ChatNavigationService();

  Future<void> openChatListing() async {
    await Get.to(() => ChatListing());
  }
}
