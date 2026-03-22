import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Modules/Education/Tests/SavedTests/saved_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';

class SavedTests extends StatefulWidget {
  const SavedTests({super.key});

  @override
  State<SavedTests> createState() => _SavedTestsState();
}

class _SavedTestsState extends State<SavedTests> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SavedTestsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'tests_saved_${identityHashCode(this)}';
    final existing = SavedTestsController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? SavedTestsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = SavedTestsController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<SavedTestsController>(tag: _controllerTag, force: true);
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
            BackButtons(text: "common.saved".tr),
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
                                EmptyRow(text: "tests.saved_empty".tr),
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
