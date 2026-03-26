part of 'editor_nickname_controller.dart';

EditorNicknameController _ensureEditorNicknameController({
  bool permanent = false,
}) {
  final existing = _maybeFindEditorNicknameController();
  if (existing != null) return existing;
  return Get.put(
    EditorNicknameController(),
    permanent: permanent,
  );
}

EditorNicknameController? _maybeFindEditorNicknameController() {
  final isRegistered = Get.isRegistered<EditorNicknameController>();
  if (!isRegistered) return null;
  return Get.find<EditorNicknameController>();
}

void _handleEditorNicknameControllerInit(EditorNicknameController controller) {
  controller._handleOnInit();
}

void _handleEditorNicknameControllerClose(EditorNicknameController controller) {
  controller._handleOnClose();
}

String _editorNicknameCurrentNormalized(
  EditorNicknameController controller,
) =>
    normalizeEditableNickname(controller.nicknameController.text);

bool _editorNicknameCanSave(EditorNicknameController controller) {
  final name = controller.currentNormalized;
  final available = controller.isAvailable.value == true;
  final longEnough = name.length >= 8;
  final changed = name != controller._originalNickname;
  final userHasInteracted = controller.hasUserTyped.value || changed;

  return available &&
      longEnough &&
      userHasInteracted &&
      !controller.isChecking.value &&
      !controller.isCooldownActive.value;
}
