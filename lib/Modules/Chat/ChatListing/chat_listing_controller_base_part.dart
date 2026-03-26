part of 'chat_listing_controller.dart';

abstract class _ChatListingControllerBase extends GetxController {
  final _state = _ChatListingControllerState();
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
}
