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
                  Row(children: [BackButtons(text: "Telefon Numarası")]),
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
                            decoration: const InputDecoration(
                              hintText: "Telefon Numarası",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
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
                        ? "Yeniden gönderim için ${controller.countdown.value}s"
                        : "Onay E-postası Gönder",
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
                        decoration: const InputDecoration(
                          counterText: "",
                          hintText: "6 haneli onay kodu",
                          border: InputBorder.none,
                          hintStyle: TextStyle(
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
                      text: "Kodu Doğrula ve Güncelle",
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
