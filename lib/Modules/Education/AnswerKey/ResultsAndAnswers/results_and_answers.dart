import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/ResultsAndAnswers/results_and_answers_controller.dart';

part 'results_and_answers_content_part.dart';
part 'results_and_answers_speedometer_part.dart';
part 'results_and_answers_speedometer_controller_part.dart';
part 'results_and_answers_speedometer_facade_part.dart';
part 'results_and_answers_speedometer_fields_part.dart';

class ResultsAndAnswers extends StatefulWidget {
  final OpticalFormModel model;

  const ResultsAndAnswers({super.key, required this.model});

  @override
  State<ResultsAndAnswers> createState() => _ResultsAndAnswersState();
}

class _ResultsAndAnswersState extends State<ResultsAndAnswers> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final ResultsAndAnswersController controller;

  OpticalFormModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'results_and_answers_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindResultsAndAnswersController(tag: _controllerTag) == null;
    controller = ensureResultsAndAnswersController(
      model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindResultsAndAnswersController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<ResultsAndAnswersController>(
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
