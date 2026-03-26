import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'biography_maker_controller.dart';

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
    final existingController = maybeFindBiographyMakerController();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ensureBiographyMakerController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindBiographyMakerController(), controller)) {
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

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(
            minHeight: 150,
            maxHeight: 150,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller.bioController,
            maxLength: 100,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'biography.hint'.tr,
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontFamily: "MontserratMedium",
                fontSize: 15,
              ),
              counterText: "",
            ),
            style: const TextStyle(
              fontSize: 15,
              fontFamily: "MontserratMedium",
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Obx(() {
              return Text(
                "${controller.currentLength.value}/100",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: "MontserratMedium",
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          return AbsorbPointer(
            absorbing: controller.isSaving.value,
            child: TurqAppButton(
              onTap: () {
                controller.setData();
              },
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
