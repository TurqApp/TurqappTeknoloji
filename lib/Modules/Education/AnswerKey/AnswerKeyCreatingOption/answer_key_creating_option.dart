import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyCreatingOption/answer_key_creating_option_controller.dart';

class AnswerKeyCreatingOption extends StatefulWidget {
  final Function onBack;

  const AnswerKeyCreatingOption({required this.onBack, super.key});

  @override
  State<AnswerKeyCreatingOption> createState() =>
      _AnswerKeyCreatingOptionState();
}

class _AnswerKeyCreatingOptionState extends State<AnswerKeyCreatingOption> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final AnswerKeyCreatingOptionController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'answer_key_option_${identityHashCode(this)}';
    _ownsController =
        maybeFindAnswerKeyCreatingOptionController(tag: _controllerTag) == null;
    controller = ensureAnswerKeyCreatingOptionController(
      widget.onBack,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          maybeFindAnswerKeyCreatingOptionController(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<AnswerKeyCreatingOptionController>(
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
            BackButtons(text: 'answer_key.new_create'.tr),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.navigateToCreateAnswerKey(context),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'answer_key.create_optical_form'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.navigateToCreateBook(context),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, color: Colors.white, size: 40),
                      SizedBox(height: 15),
                      Text(
                        'answer_key.create_booklet_answer_key'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
