part of 'editor_phone_number.dart';

extension _EditorPhoneNumberShellPart on _EditorPhoneNumberState {
  Widget _buildEditorPhoneNumberShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Obx(() => _buildEditorPhoneNumberContent()),
          ),
        ),
      ),
    );
  }
}
