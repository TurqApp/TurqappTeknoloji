import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import 'view_changer_controller.dart';

part 'view_changer_shell_part.dart';
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

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
