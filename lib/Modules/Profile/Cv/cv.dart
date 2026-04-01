import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv_controller.dart';

part 'cv_personal_part.dart';
part 'cv_education_part.dart';
part 'cv_other_part.dart';
part 'cv_shell_part.dart';
part 'cv_shell_content_part.dart';
part 'cv_shell_layout_part.dart';

class Cv extends StatefulWidget {
  const Cv({super.key});

  @override
  State<Cv> createState() => _CvState();
}

class _CvState extends State<Cv> {
  late final CvController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'cv_${identityHashCode(this)}';
    controller = ensureCvController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (maybeFindCvController(tag: _controllerTag) != null &&
        identical(
          maybeFindCvController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<CvController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildCvShell(context);
  }
}
