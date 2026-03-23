part of 'support_contact_view.dart';

extension SupportContactViewLifecyclePart on _SupportContactViewState {
  void _updateViewState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
