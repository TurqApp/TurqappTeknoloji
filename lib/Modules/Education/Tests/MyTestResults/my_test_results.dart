import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTestResults/my_test_results_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestPastResultContent/test_past_result_content.dart';

class MyTestResults extends StatelessWidget {
  const MyTestResults({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyTestResultsController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Sonuçlar"),
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
                                children: const [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Sonuç bulunamadı.\nDaha önce hiç test çözmediniz.",
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
