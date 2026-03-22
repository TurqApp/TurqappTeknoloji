import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';
import 'career_profile_controller.dart';

part 'career_profile_content_part.dart';
part 'career_profile_sections_part.dart';

class CareerProfile extends StatefulWidget {
  const CareerProfile({super.key});

  @override
  State<CareerProfile> createState() => _CareerProfileState();
}

class _CareerProfileState extends State<CareerProfile> {
  late final String _controllerTag;
  late final CareerProfileController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'career_profile_${identityHashCode(this)}';
    _ownsController =
        CareerProfileController.maybeFind(tag: _controllerTag) == null;
    controller = CareerProfileController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          CareerProfileController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<CareerProfileController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
