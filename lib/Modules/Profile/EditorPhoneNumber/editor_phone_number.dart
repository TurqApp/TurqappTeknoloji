import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/EditorPhoneNumber/editor_phone_number_controller.dart';

class EditorPhoneNumber extends StatelessWidget {
  EditorPhoneNumber({super.key});
  final controller = Get.put(EditorPhoneNumberController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Obx(() {
              final canSend =
                  controller.countdown.value == 0 && !controller.isBusy.value;
              final canConfirm =
                  controller.isCodeSent.value && !controller.isBusy.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [BackButtons(text: 'editor_phone.title'.tr)]),
                  const SizedBox(height: 12),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        const Text(
                          "+90",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.phoneController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'editor_phone.phone_hint'.tr,
                              border: InputBorder.none,
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TurqAppButton(
                    onTap: () {
                      if (canSend) {
                        controller.sendEmailApproval();
                      }
                    },
                    bgColor: canSend ? Colors.black : Colors.grey,
                    text: controller.countdown.value > 0
                        ? 'editor_phone.resend_in'
                            .trParams({'seconds': '${controller.countdown.value}'})
                        : 'editor_phone.send_approval'.tr,
                  ),
                  if (controller.isCodeSent.value) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: controller.codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: 'editor_phone.code_hint'.tr,
                          border: InputBorder.none,
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TurqAppButton(
                      onTap: () {
                        if (canConfirm) {
                          controller.confirmAndUpdatePhone();
                        }
                      },
                      bgColor: canConfirm ? Colors.black : Colors.grey,
                      text: 'editor_phone.verify_update'.tr,
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
