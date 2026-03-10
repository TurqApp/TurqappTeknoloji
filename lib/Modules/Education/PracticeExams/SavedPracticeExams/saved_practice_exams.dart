import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';

class SavedPracticeExams extends StatelessWidget {
  const SavedPracticeExams({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SavedPracticeExamsController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Kaydedilenler"),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (controller.savedExams.isEmpty) {
                  return const Center(
                    child: Text(
                      "Kaydedilen sınav bulunmuyor.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: GridView.builder(
                    itemCount: controller.savedExams.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.49,
                    ),
                    itemBuilder: (context, index) {
                      return DenemeGrid(
                        model: controller.savedExams[index],
                        getData: controller.loadSavedExams,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
