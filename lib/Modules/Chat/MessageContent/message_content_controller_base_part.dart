part of 'message_content_controller.dart';

abstract class _MessageContentControllerBase extends GetxController {
  _MessageContentControllerBase({
    required MessageModel model,
    required String mainID,
  }) : _state = _MessageContentControllerState(
          model: model,
          mainID: mainID,
        );

  final _MessageContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleMessageContentInit(this as MessageContentController);
  }
}
