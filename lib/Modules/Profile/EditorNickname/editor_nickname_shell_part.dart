part of 'editor_nickname.dart';

extension _EditorNicknameShellPart on _EditorNicknameState {
  Widget _buildEditorNicknameShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'editor_nickname.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Obx(() => _buildEditorNicknameContent()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
