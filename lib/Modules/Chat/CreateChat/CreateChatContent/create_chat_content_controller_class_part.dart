part of 'create_chat_content_controller.dart';

class CreateChatContentController extends GetxController {
  final _state = _CreateChatContentControllerState();
  String userID;

  CreateChatContentController({required this.userID});

  @override
  void onInit() {
    super.onInit();
    _handleCreateChatContentInit(this);
  }
}
