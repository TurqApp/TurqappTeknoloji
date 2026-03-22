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
part 'job_creator_formatters_part.dart';
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
