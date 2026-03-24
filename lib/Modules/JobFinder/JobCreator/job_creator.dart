import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Utils/phone_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/job_model.dart';

import 'job_creator_controller.dart';

part 'job_creator_content_part.dart';
part 'job_creator_form_part.dart';
part 'job_creator_ui_part.dart';

class JobCreator extends StatefulWidget {
  const JobCreator({super.key, this.existingJob});

  final JobModel? existingJob;

  @override
  State<JobCreator> createState() => _JobCreatorState();
}

class _JobCreatorState extends State<JobCreator> {
  late final String _tag;
  late final JobCreatorController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'job_creator_${widget.existingJob?.docID ?? 'new'}_${identityHashCode(this)}';
    _ownsController = JobCreatorController.maybeFind(tag: _tag) == null;
    controller = JobCreatorController.ensure(
      existingJob: widget.existingJob,
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(JobCreatorController.maybeFind(tag: _tag), controller)) {
      Get.delete<JobCreatorController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildScaffold(context);
}

class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = phoneDigitsOnly(newValue.text);
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;

    if (clipped.length >= 2) {
      final hour = int.tryParse(clipped.substring(0, 2)) ?? -1;
      if (hour < 0 || hour > 23) {
        return oldValue;
      }
    }

    if (clipped.length >= 3) {
      final minuteTens = int.tryParse(clipped.substring(2, 3)) ?? -1;
      if (minuteTens < 0 || minuteTens > 5) {
        return oldValue;
      }
    }

    if (clipped.length == 4) {
      final minute = int.tryParse(clipped.substring(2, 4)) ?? -1;
      if (minute < 0 || minute > 59) {
        return oldValue;
      }
    }

    final formatted = clipped.length <= 2
        ? clipped
        : '${clipped.substring(0, 2)}:${clipped.substring(2)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ThousandsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = phoneDigitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final reversed = digits.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    final formatted = chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
