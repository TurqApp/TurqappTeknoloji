import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/external.dart';
import 'optical_form_entry_controller.dart';

part 'optical_form_entry_content_part.dart';
part 'optical_form_entry_result_part.dart';

class OpticalFormEntry extends StatefulWidget {
  const OpticalFormEntry({super.key});

  @override
  State<OpticalFormEntry> createState() => _OpticalFormEntryState();
}

class _OpticalFormEntryState extends State<OpticalFormEntry> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final OpticalFormEntryController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'optical_form_entry_${identityHashCode(this)}';
    _ownsController =
        maybeFindOpticalFormEntryController(tag: _controllerTag) == null;
    controller = ensureOpticalFormEntryController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindOpticalFormEntryController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<OpticalFormEntryController>(
          tag: _controllerTag,
          force: true,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _buildBody(context),
      ),
    );
  }
}
