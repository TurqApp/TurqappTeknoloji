import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Modules/Education/Tests/SavedTests/saved_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';

class SavedTests extends StatelessWidget {
  const SavedTests({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SavedTestsController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Kaydedilenler"),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            radius: 20,
                            color: Colors.black,
                          ),
                        )
                      : controller.list.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                EmptyRow(
                                    text: "Kaydedilen test bulunmamaktadır."),
                              ],
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.only(left: 15, right: 15),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 5.0,
                                  mainAxisSpacing: 5.0,
                                  childAspectRatio: 1.85 / 3.6,
                                ),
                                itemCount: controller.list.length,
                                itemBuilder: (context, index) {
                                  return TestsGrid(
                                      model: controller.list[index]);
                                },
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
