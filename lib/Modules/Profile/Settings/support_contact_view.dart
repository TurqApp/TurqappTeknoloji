import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/support_message_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

part 'support_contact_view_card_part.dart';

class SupportContactView extends StatefulWidget {
  const SupportContactView({super.key});

  @override
  State<SupportContactView> createState() => _SupportContactViewState();
}

class _SupportContactViewState extends State<SupportContactView> {
  final TextEditingController _messageController = TextEditingController();
  final SupportMessageRepository _repository =
      SupportMessageRepository.ensure();
  bool _sending = false;
  String _selectedTopicKey = _supportTopicKeys.first;

  void _updateViewState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'support.title'.tr),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildSupportCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _supportTopicKeys = <String>[
  'support.topic.account',
  'support.topic.payment',
  'support.topic.technical',
  'support.topic.content',
  'support.topic.suggestion',
];
