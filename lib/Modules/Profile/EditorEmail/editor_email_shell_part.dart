part of 'editor_email.dart';

extension _EditorEmailShellPart on _EditorEmailState {
  Widget _buildEditorEmailShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Obx(() => _buildEditorEmailContent()),
          ),
        ),
      ),
    );
  }
}
