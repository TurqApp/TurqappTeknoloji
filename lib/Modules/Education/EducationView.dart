import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Modules/Education/EducationController.dart';
import 'package:turqappv2/Modules/TypeWriter/TypeWriter.dart';

class EducationView extends StatelessWidget {
  EducationView({super.key});

  final EducationController controller = Get.put(EducationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypewriterText(
                  text: "Eğitim",
                  fontSize: 25,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: controller.titles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => controller.navigateToModule(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: controller.colors[index],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Icon(
                                controller.icons[index],
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                controller.titles[index],
                                style: TextStyles.antremanTitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
