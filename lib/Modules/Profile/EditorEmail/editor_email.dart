import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email_controller.dart';

part 'editor_email_content_part.dart';

class EditorEmail extends StatefulWidget {
  const EditorEmail({super.key});

  @override
  State<EditorEmail> createState() => _EditorEmailState();
}

class _EditorEmailState extends State<EditorEmail> {
  late final EditorEmailController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existingController = EditorEmailController.maybeFind();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = EditorEmailController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(EditorEmailController.maybeFind(), controller)) {
      Get.delete<EditorEmailController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Obx(() => _buildEditorEmailContent()),
          ),
        ),
      ),
    );
  }
}
