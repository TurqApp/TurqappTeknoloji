import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'biography_maker_controller.dart';

class BiographyMaker extends StatelessWidget {
  BiographyMaker({super.key});
  final controller = Get.put(BiographyMakerController());
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
                  child: Column(
                    children: [
                      Container(
                        constraints: BoxConstraints(
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
                                fontSize: 15),
                            counterText: "",
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Obx(() {
                            return Text(
                              "${controller.currentLength.value}/100",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontFamily: "MontserratMedium",
                              ),
                            );
                          })
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
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
                      SizedBox(
                        height: 12,
                      ),
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
