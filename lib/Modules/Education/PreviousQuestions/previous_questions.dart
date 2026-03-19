import 'package:carousel_slider/carousel_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Modules/Education/PreviousQuestions/previous_questions_controller.dart';
import 'package:turqappv2/Themes/app_assets.dart';

class PreviousQuestions extends StatelessWidget {
  const PreviousQuestions({super.key});

  @override
  Widget build(BuildContext context) {
    final PreviousQuestionsController controller = Get.put(
      PreviousQuestionsController(),
    );

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
