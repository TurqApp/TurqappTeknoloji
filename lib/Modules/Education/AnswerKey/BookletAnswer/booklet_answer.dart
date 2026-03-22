import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletAnswer/booklet_answer_controller.dart';

part 'booklet_answer_shell_part.dart';
part 'booklet_answer_result_part.dart';

class BookletAnswer extends StatefulWidget {
  final AnswerKeySubModel model;
  final BookletModel anaModel;

  const BookletAnswer({required this.model, required this.anaModel, super.key});

  @override
  State<BookletAnswer> createState() => _BookletAnswerState();
}

class _BookletAnswerState extends State<BookletAnswer> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final BookletAnswerController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'booklet_answer_${widget.anaModel.docID}_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        BookletAnswerController.maybeFind(tag: _controllerTag) == null;
    controller = BookletAnswerController.ensure(
      widget.model,
      widget.anaModel,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = BookletAnswerController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<BookletAnswerController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _buildBody(context),
      ),
    );
  }
}
