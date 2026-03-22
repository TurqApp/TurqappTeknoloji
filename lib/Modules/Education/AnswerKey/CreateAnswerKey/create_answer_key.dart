import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/pasaj_selection_chip.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateAnswerKey/create_answer_key_controller.dart';

part 'create_answer_key_editor_part.dart';
part 'create_answer_key_duration_part.dart';

class CreateAnswerKey extends StatefulWidget {
  final Function onBack;

  const CreateAnswerKey({required this.onBack, super.key});

  @override
  State<CreateAnswerKey> createState() => _CreateAnswerKeyState();
}

class _CreateAnswerKeyState extends State<CreateAnswerKey> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final CreateAnswerKeyController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'create_answer_key_${identityHashCode(this)}';
    _ownsController =
        CreateAnswerKeyController.maybeFind(tag: _controllerTag) == null;
    controller = CreateAnswerKeyController.ensure(
      widget.onBack,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = CreateAnswerKeyController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<CreateAnswerKeyController>(
          tag: _controllerTag,
          force: true,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
