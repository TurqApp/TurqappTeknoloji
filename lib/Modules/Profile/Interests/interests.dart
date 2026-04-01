import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/interests_list.dart';
import 'package:turqappv2/Modules/Profile/Interests/interest_controller.dart';
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
        maybeFindInterestsController(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ensureInterestsController(tag: _controllerTag);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindInterestsController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<InterestsController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.interests".tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildInterestsContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
