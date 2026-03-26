part of 'editor_nickname_controller.dart';

abstract class _EditorNicknameControllerBase extends GetxController {
  final _state = _EditorNicknameControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleEditorNicknameControllerInit(this as EditorNicknameController);
  }

  @override
  void onClose() {
    _handleEditorNicknameControllerClose(this as EditorNicknameController);
    super.onClose();
  }
}
