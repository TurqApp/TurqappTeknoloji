part of 'clickable_text_content.dart';

class ClickableTextController extends GetxController {
  final _ClickableTextControllerState _state;

  ClickableTextController._(_ClickableTextControllerConfig config)
      : _state = _ClickableTextControllerState(config);

  @override
  void onInit() {
    super.onInit();
    _handleClickableTextControllerInit(this);
  }

  @override
  void onClose() {
    _handleClickableTextControllerClose(this);
    super.onClose();
  }
}
