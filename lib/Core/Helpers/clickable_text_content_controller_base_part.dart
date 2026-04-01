part of 'clickable_text_content.dart';

abstract class _ClickableTextControllerBase extends GetxController {
  _ClickableTextControllerBase._(_ClickableTextControllerConfig config)
      : _state = _ClickableTextControllerState(config);

  final _ClickableTextControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleClickableTextControllerInit(this as ClickableTextController);
  }

  @override
  void onClose() {
    _handleClickableTextControllerClose(this as ClickableTextController);
    super.onClose();
  }
}
