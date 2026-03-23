part of 'support_contact_view.dart';

extension SupportContactViewFormPart on _SupportContactViewState {
  Widget _buildMessageField() {
    return TextField(
      controller: _messageController,
      maxLines: 7,
      minLines: 5,
      decoration: InputDecoration(
        hintText: 'support.message_hint'.tr,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black54),
        ),
      ),
    );
  }
}
