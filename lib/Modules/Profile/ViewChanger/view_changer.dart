import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import 'view_changer_controller.dart';

part 'view_changer_selection_part.dart';

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
    controller = ViewChangerController.ensure(
      selection: initialSelection,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (ViewChangerController.maybeFind(tag: _controllerTag) != null &&
        identical(
          ViewChangerController.maybeFind(tag: _controllerTag),
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

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
