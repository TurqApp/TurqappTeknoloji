part of 'editor_nickname_controller.dart';

class EditorNicknameController extends GetxController {
  final _state = _EditorNicknameControllerState();
  static const Duration _graceWindow = Duration(hours: 1);
  static const Duration _changeCooldown = Duration(days: 15);

  @override
  void onInit() {
    super.onInit();
    _handleEditorNicknameControllerInit(this);
  }

  @override
  void onClose() {
    _handleEditorNicknameControllerClose(this);
    super.onClose();
  }
}
