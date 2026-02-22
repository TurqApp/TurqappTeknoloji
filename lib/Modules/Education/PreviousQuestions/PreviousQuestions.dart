import 'package:carousel_slider/carousel_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/Slider/EducationSlider.dart';
import 'package:turqappv2/Modules/Education/PreviousQuestions/PreviousQuestionsController.dart';
import 'package:turqappv2/Themes/AppAssets.dart';

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
        autoPlayInterval: Duration(seconds: 3),
        enableInfiniteScroll: true,
        scrollDirection: Axis.horizontal,
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Çıkmış Sorular"),
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
