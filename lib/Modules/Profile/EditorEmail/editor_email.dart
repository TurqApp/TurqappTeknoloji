import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email_controller.dart';

class EditorEmail extends StatelessWidget {
  EditorEmail({super.key});
  final controller = Get.put(EditorEmailController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Obx(() {
              final canSend =
                  controller.countdown.value == 0 && !controller.isBusy.value;
              final canUpdate =
                  controller.isCodeSent.value && !controller.isBusy.value;

              return Column(
                children: [
                  Row(children: [BackButtons(text: "E-posta Onayı")]),
                  const SizedBox(height: 12),
                  Container(
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: controller.emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: "Hesap e-posta adresiniz",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "MontserratMedium"),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TurqAppButton(
                    onTap: () {
                      if (canSend) {
                        controller.sendEmailCode();
                      }
                    },
                    bgColor: canSend ? Colors.black : Colors.grey,
                    text: controller.countdown.value > 0
                        ? "Yeniden gönderim için ${controller.countdown.value}s"
                        : "Onay Kodu Gönder",
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Bu onay güvenlik amaçlıdır. Onaylamasanız da uygulamayı kullanmaya devam edebilirsiniz.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                  if (controller.isCodeSent.value) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 50,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: controller.codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            counterText: "",
                            hintText: "6 haneli onay kodu",
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: "MontserratMedium"),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TurqAppButton(
                      onTap: () {
                        if (canUpdate) {
                          controller.verifyAndConfirmEmail();
                        }
                      },
                      bgColor: canUpdate ? Colors.black : Colors.grey,
                      text: "Kodu Doğrula ve Onayla",
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
