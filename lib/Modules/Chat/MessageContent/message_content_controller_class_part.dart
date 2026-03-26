part of 'message_content_controller.dart';

class MessageContentController extends GetxController {
  final _MessageContentControllerState _state;

  MessageContentController({
    required MessageModel model,
    required String mainID,
  }) : _state = _MessageContentControllerState(
          model: model,
          mainID: mainID,
        );

  @override
  void onInit() {
    super.onInit();
    _handleMessageContentInit(this);
  }
}
