import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import 'view_changer_controller.dart';

class ViewChanger extends StatefulWidget {
  const ViewChanger({super.key});

  @override
  State<ViewChanger> createState() => _ViewChangerState();
}

class _ViewChangerState extends State<ViewChanger> {
  final userService = CurrentUserService.instance;
  late final ViewChangerController controller;

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'view_changer_${identityHashCode(this)}';
    final initialSelection = (userService.currentUser?.viewSelection ?? 1).obs;
    controller = ensureViewChangerController(
      selection: initialSelection,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (maybeFindViewChangerController(tag: _controllerTag) != null &&
        identical(
          maybeFindViewChangerController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ViewChangerController>(tag: _controllerTag);
    }
    super.dispose();
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'view_changer.title'.tr),
            Expanded(
              child: ListView(
                children: [
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              controller.updateViewMode(0);
                              Get.back();
                            },
                            child: _buildClassicSelection(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Divider(
                              color: Colors.grey.withAlpha(50),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              controller.updateViewMode(1);
                              Get.back();
                            },
                            child: _buildModernSelection(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionHeader(
          label: 'view_changer.classic'.tr,
          isSelected: controller.selection.value == 0,
        ),
        7.ph,
        Padding(
          padding: const EdgeInsets.only(left: 33),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: controller.selection.value == 0
                    ? Colors.blueAccent
                    : Colors.grey.withAlpha(50),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: Image.asset("assets/images/klasikview.webp"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionHeader(
          label: 'view_changer.modern'.tr,
          isSelected: controller.selection.value == 1,
        ),
        7.ph,
        Padding(
          padding: const EdgeInsets.only(left: 33),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: controller.selection.value == 1
                    ? Colors.blueAccent
                    : Colors.grey.withAlpha(50),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: Image.asset("assets/images/modernview.webp"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader({
    required String label,
    required bool isSelected,
  }) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
        7.pw,
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratBold",
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
