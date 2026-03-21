import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email_controller.dart';

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
    if (Get.isRegistered<EditorEmailController>()) {
      controller = Get.find<EditorEmailController>();
      _ownsController = false;
    } else {
      controller = Get.put(EditorEmailController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<EditorEmailController>() &&
        identical(Get.find<EditorEmailController>(), controller)) {
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
            child: Obx(() {
              final canSend =
                  controller.countdown.value == 0 && !controller.isBusy.value;
              final canUpdate =
                  controller.isCodeSent.value && !controller.isBusy.value;

              return Column(
                children: [
                  Row(children: [BackButtons(text: 'editor_email.title'.tr)]),
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
                        decoration: InputDecoration(
                          hintText: 'editor_email.email_hint'.tr,
                          hintStyle: const TextStyle(
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
                        ? 'editor_email.resend_in'
                            .trParams({'seconds': '${controller.countdown.value}'})
                        : 'editor_email.send_code'.tr,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'editor_email.note'.tr,
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
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: 'editor_email.code_hint'.tr,
                            hintStyle: const TextStyle(
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
                      text: 'editor_email.verify_confirm'.tr,
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
