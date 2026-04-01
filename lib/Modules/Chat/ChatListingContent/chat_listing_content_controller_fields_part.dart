part of 'chat_listing_content_controller.dart';

class _ChatListingContentControllerState {
  _ChatListingContentControllerState({
    required this.userID,
    required this.model,
  });

  String userID;
  ChatListingModel model;
  final RxInt notReadCounter = 0.obs;
  final RxList<MessageModel> lastMessage = <MessageModel>[].obs;
  Worker? listWorker;
}

extension ChatListingContentControllerFieldsPart
    on ChatListingContentController {
  String get userID => _state.userID;
  set userID(String value) => _state.userID = value;
  ChatListingModel get model => _state.model;
  set model(ChatListingModel value) => _state.model = value;
  RxInt get notReadCounter => _state.notReadCounter;
  RxList<MessageModel> get lastMessage => _state.lastMessage;
  Worker? get _listWorker => _state.listWorker;
  set _listWorker(Worker? value) => _state.listWorker = value;
}
