import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/functions.dart';
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
              final isPhoneValid = controller.phoneController.text.length == 10;
              final isOtpValid = controller.inputOtp.text.length == 6;
              final canSendOtp = controller.countdown.value == 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BackButtons(text: "Telefon Numarası"),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Telefon numarası input alanı
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
                          child: controller.lock.value
                              ? Text(
                                  controller.phoneController.text,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                )
                              : TextField(
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

                  // 🔽 OTP alanı sadece doğrulama kodu gönderildikten sonra görünür
                  if (controller.lock.value) ...[
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
                          Expanded(
                            child: TextField(
                              controller: controller.inputOtp,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                counterText: "",
                                hintText: "6 haneli doğrulama kodu",
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
                          Text(
                            "${controller.countdown.value}s",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                  SizedBox(
                    height: 12,
                  ),
                  if (isOtpValid)
                    TurqAppButton(
                      onTap: () {
                        if (controller.verifyOtp(controller.inputOtp.text)) {
                          controller.setData();
                          controller.isVerified.value = true;
                          AppSnackbar("Başarılı",
                              "Telefon numaranız güncellendi ve doğrulandı.");
                        } else {
                          showAlertDialog(
                            context,
                            "Hatalı Kod",
                            "Girdiğiniz doğrulama kodu hatalı. Lütfen tekrar deneyin.",
                          );
                        }
                      },
                      text: "Doğrula",
                    )

                  // 🔘 Doğrulama kodu gönder butonu
                  else if (isPhoneValid && !controller.isVerified.value)
                    TurqAppButton(
                      onTap: () {
                        if (canSendOtp) {
                          controller.sendOtpCode();
                        }
                      },
                      bgColor: canSendOtp ? Colors.black : Colors.grey,
                      text: canSendOtp
                          ? "Doğrulama Kodu Gönder"
                          : "Yeniden gönderim için ${controller.countdown.value}s",
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
