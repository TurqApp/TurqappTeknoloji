import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/interests_list.dart';
import 'package:turqappv2/Modules/Profile/Interests/interest_controller.dart';

part 'interests_shell_part.dart';
part 'interests_content_part.dart';

class Interests extends StatefulWidget {
  const Interests({super.key});

  @override
  State<Interests> createState() => _InterestsState();
}

class _InterestsState extends State<Interests> {
  late final String _controllerTag;
  late final InterestsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'profile_interests_${identityHashCode(this)}';
    final existingController =
        InterestsController.maybeFind(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = InterestsController.ensure(tag: _controllerTag);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          InterestsController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<InterestsController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildInterestsShell(context);
  }
}
