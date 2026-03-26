import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Modules/Profile/ProfileContact/profile_contant_controller.dart';

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
        maybeFindProfileContactController(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ensureProfileContactController(tag: _controllerTag);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindProfileContactController(tag: _controllerTag),
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

  Widget _buildCallVisibilityTile() {
    return Obx(() {
      return _buildVisibilityTile(
        icon: CupertinoIcons.phone,
        label: 'profile_contact.call'.tr,
        isOn: controller.isCallVisible.value,
        onTap: controller.toggleCallVisibility,
      );
    });
  }

  Widget _buildEmailVisibilityTile() {
    return Obx(() {
      return _buildVisibilityTile(
        icon: CupertinoIcons.at,
        label: 'profile_contact.email'.tr,
        isOn: controller.isEmailVisible.value,
        onTap: controller.toggleEmailVisibility,
      );
    });
  }

  Widget _buildVisibilityTile({
    required IconData icon,
    required String label,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: TurqAppToggle(isOn: isOn),
            ),
          ],
        ),
      ),
    );
  }
}
