part of 'support_contact_view.dart';

extension SupportContactViewLifecyclePart on _SupportContactViewState {
  void _handleDispose() {
    _messageController.dispose();
  }
}
