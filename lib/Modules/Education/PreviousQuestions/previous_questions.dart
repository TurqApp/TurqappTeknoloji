import 'package:carousel_slider/carousel_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Modules/Education/PreviousQuestions/previous_questions_controller.dart';
import 'package:turqappv2/Themes/app_assets.dart';

class PreviousQuestions extends StatefulWidget {
  const PreviousQuestions({super.key});

  @override
  State<PreviousQuestions> createState() => _PreviousQuestionsState();
}

class _PreviousQuestionsState extends State<PreviousQuestions> {
  late final PreviousQuestionsController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'previous_questions_${identityHashCode(this)}';
    controller = Get.isRegistered<PreviousQuestionsController>(
      tag: _controllerTag,
    )
        ? Get.find<PreviousQuestionsController>(tag: _controllerTag)
        : Get.put(PreviousQuestionsController(), tag: _controllerTag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.setOptions(
      CarouselOptions(
        height: MediaQuery.of(context).size.width / 2.5,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 2),
        enableInfiniteScroll: true,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<PreviousQuestionsController>(tag: _controllerTag) &&
        identical(
          Get.find<PreviousQuestionsController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PreviousQuestionsController>(tag: _controllerTag);
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
            BackButtons(text: "education.previous_questions".tr),
            EducationSlider(
              imageList: [
                AppAssets.previous1,
                AppAssets.previous2,
                AppAssets.previous3,
                AppAssets.previous4,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
