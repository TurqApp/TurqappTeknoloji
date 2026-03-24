import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'biography_maker_controller.dart';

part 'biography_maker_content_part.dart';

class BiographyMaker extends StatefulWidget {
  const BiographyMaker({super.key});

  @override
  State<BiographyMaker> createState() => _BiographyMakerState();
}

class _BiographyMakerState extends State<BiographyMaker> {
  late final BiographyMakerController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existingController = BiographyMakerController.maybeFind();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = BiographyMakerController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(BiographyMakerController.maybeFind(), controller)) {
      Get.delete<BiographyMakerController>(force: true);
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
            BackButtons(text: 'biography.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
