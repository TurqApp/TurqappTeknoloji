import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/support_message_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

part 'support_contact_view_shell_part.dart';
part 'support_contact_view_card_part.dart';
part 'support_contact_view_form_part.dart';
part 'support_contact_view_submit_part.dart';
part 'support_contact_view_topics_part.dart';
part 'support_contact_view_actions_part.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }
}
