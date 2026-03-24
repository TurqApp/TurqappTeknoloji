import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Modules/Profile/ProfileContact/profile_contant_controller.dart';

part 'profile_contact_content_part.dart';

class ProfileContact extends StatefulWidget {
  const ProfileContact({super.key});

  @override
  State<ProfileContact> createState() => _ProfileContactState();
}

class _ProfileContactState extends State<ProfileContact> {
  late final String _controllerTag;
  late final ProfileContactController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'profile_contact_${identityHashCode(this)}';
    final existingController =
        ProfileContactController.maybeFind(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ProfileContactController.ensure(tag: _controllerTag);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          ProfileContactController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ProfileContactController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'profile_contact.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _buildCallVisibilityTile(),
                      const SizedBox(height: 12),
                      _buildEmailVisibilityTile(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
