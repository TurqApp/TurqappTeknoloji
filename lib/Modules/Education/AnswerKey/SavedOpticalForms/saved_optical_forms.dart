import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms_controller.dart';

class SavedOpticalForms extends StatefulWidget {
  const SavedOpticalForms({super.key});

  @override
  State<SavedOpticalForms> createState() => _SavedOpticalFormsState();
}

class _SavedOpticalFormsState extends State<SavedOpticalForms> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SavedOpticalFormsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'saved_optical_forms_${identityHashCode(this)}';
    _ownsController =
        SavedOpticalFormsController.maybeFind(tag: _controllerTag) == null;
    controller = SavedOpticalFormsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = SavedOpticalFormsController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<SavedOpticalFormsController>(
          tag: _controllerTag,
          force: true,
        );
      }
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
            BackButtons(text: 'common.saved'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(child: CupertinoActivityIndicator())
                      : Obx(
                          () => controller.list.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    'answer_key.saved_empty'.tr,
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
                                      childAspectRatio: 0.49,
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
