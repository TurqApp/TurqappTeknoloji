import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/applications_controller.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';

part 'applications_view_actions_part.dart';
part 'applications_view_content_part.dart';

class ApplicationsView extends StatefulWidget {
  ApplicationsView({super.key});

  @override
  State<ApplicationsView> createState() => _ApplicationsViewState();
}

class _ApplicationsViewState extends State<ApplicationsView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final ApplicationsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_applications_${identityHashCode(this)}';
    final existing = maybeFindApplicationsController(_controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensureApplicationsController(_controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindApplicationsController(_controllerTag),
          controller,
        )) {
      Get.delete<ApplicationsController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
