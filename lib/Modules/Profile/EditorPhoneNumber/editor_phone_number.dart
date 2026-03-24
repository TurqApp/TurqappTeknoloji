import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/EditorPhoneNumber/editor_phone_number_controller.dart';

part 'editor_phone_number_content_part.dart';

class EditorPhoneNumber extends StatefulWidget {
  const EditorPhoneNumber({super.key});

  @override
  State<EditorPhoneNumber> createState() => _EditorPhoneNumberState();
}

class _EditorPhoneNumberState extends State<EditorPhoneNumber> {
  late final EditorPhoneNumberController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existingController = EditorPhoneNumberController.maybeFind();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = EditorPhoneNumberController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(EditorPhoneNumberController.maybeFind(), controller)) {
      Get.delete<EditorPhoneNumberController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Obx(() => _buildEditorPhoneNumberContent()),
          ),
        ),
      ),
    );
  }
}
