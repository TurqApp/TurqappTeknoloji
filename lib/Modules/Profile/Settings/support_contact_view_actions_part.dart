part of 'support_contact_view.dart';

extension SupportContactViewActionsPart on _SupportContactViewState {
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _sending ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _sending
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
                'support.send'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'MontserratSemiBold',
                ),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_sending) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      AppSnackbar('support.empty_title'.tr, 'support.empty_body'.tr);
      return;
    }

    _updateViewState(() => _sending = true);
    try {
      await _repository.createMessage(
        topic: _selectedTopicKey.tr,
        message: message,
      );
      _messageController.clear();
      AppSnackbar('support.sent_title'.tr, 'support.sent_body'.tr);
    } catch (e) {
      AppSnackbar('support.error_title'.tr, _friendlyErrorMessage(e));
    } finally {
      _updateViewState(() => _sending = false);
    }
  }

  String _friendlyErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('not_authenticated')) {
      return 'support.error_not_authenticated'.tr;
    }
    if (raw.contains('empty_topic')) {
      return 'support.error_empty_topic'.tr;
    }
    if (raw.contains('empty_message')) {
      return 'support.empty_body'.tr;
    }
    return '${'support.error_body'.tr} $error';
  }
}
