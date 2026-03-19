import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/LessonsBasedTests/lesson_based_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';

class LessonBasedTests extends StatelessWidget {
  final String testTuru;

  const LessonBasedTests({super.key, required this.testTuru});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LessonBasedTestsController(testTuru));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackButtons(
              text: "tests.lesson_based_title".trParams({"type": testTuru}),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  onRefresh: controller.getData,
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(child: CupertinoActivityIndicator())
                        : controller.list
                                .where((test) => test.testTuru == testTuru)
                                .isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 5.0,
                                    mainAxisSpacing: 5.0,
                                    childAspectRatio: 1.85 / 3.6,
                                  ),
                                  itemCount: controller.list
                                      .where(
                                        (test) => test.testTuru == testTuru,
                                      )
                                      .length,
                                  itemBuilder: (context, index) {
                                    return TestsGrid(
                                      model: controller.list
                                          .where(
                                            (test) => test.testTuru == testTuru,
                                          )
                                          .toList()[index],
                                      update: controller.getData,
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline,
                                            color: Colors.black,
                                          ),
                                          SizedBox(height: 7),
                                          Text(
                                            "tests.none_in_category".tr,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: "Montserrat",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
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
