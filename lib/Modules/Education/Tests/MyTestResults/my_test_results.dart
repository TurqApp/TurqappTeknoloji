import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTestResults/my_test_results_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestPastResultContent/test_past_result_content.dart';

class MyTestResults extends StatefulWidget {
  const MyTestResults({super.key});

  @override
  State<MyTestResults> createState() => _MyTestResultsState();
}

class _MyTestResultsState extends State<MyTestResults> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final MyTestResultsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'tests_results_${identityHashCode(this)}';
    final existing = MyTestResultsController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller =
        existing ?? MyTestResultsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = MyTestResultsController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<MyTestResultsController>(tag: _controllerTag, force: true);
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
            BackButtons(text: "tests.results_title".tr),
            Expanded(
              child: RefreshIndicator(
                color: Colors.white,
                backgroundColor: Colors.black,
                onRefresh: controller.findAndGetTestler,
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(child: CupertinoActivityIndicator())
                      : controller.list.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "tests.my_results_empty".tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: controller.list.length,
                              itemBuilder: (context, index) {
                                return TestPastResultContent(
                                  index: index,
                                  model: controller.list[index],
                                );
                              },
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
