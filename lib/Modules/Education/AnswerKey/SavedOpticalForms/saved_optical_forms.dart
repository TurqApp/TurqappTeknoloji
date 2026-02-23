import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms_controller.dart';

class SavedOpticalForms extends StatelessWidget {
  const SavedOpticalForms({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SavedOpticalFormsController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Kaydedilenler"),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(child: CupertinoActivityIndicator())
                      : Obx(
                          () => controller.list.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Text(
                                    "Kaydedilen kitapçık yok.",
                                    style: TextStyle(
                                      fontFamily: "MontserratMedium",
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 5.0,
                                      mainAxisSpacing: 5.0,
                                      childAspectRatio: 2.4 / 5.4,
                                    ),
                                    itemCount: controller.list.length,
                                    itemBuilder: (context, index) {
                                      final item = controller.list[index];
                                      return AnswerKeyContent(
                                        model: item,
                                        onUpdate: (v) => controller.getData(),
                                      );
                                    },
                                  ),
                                ),
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
