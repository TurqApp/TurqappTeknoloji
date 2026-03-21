import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Modules/Education/Tests/AddTestQuestion/add_test_question_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content.dart';

class AddTestQuestion extends StatelessWidget {
  final List<TestReadinessModel> soruList;
  final String testID;
  final String testTuru;
  final Function update;

  const AddTestQuestion({
    super.key,
    required this.soruList,
    required this.testID,
    required this.update,
    required this.testTuru,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AddTestQuestionController(
        initialSoruList: soruList,
        testID: testID,
        testTuru: testTuru,
        onUpdate: update,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 70,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  const AppBackButton(
                    icon: Icons.arrow_back_sharp,
                    iconColor: Colors.white,
                    surfaceColor: Color(0x1FFFFFFF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "tests.add_question".tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      : Column(
                          children: [
                            Expanded(
                              child: controller.soruList.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.black,
                                            size: 40,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            "tests.no_questions_added".tr,
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
                                      itemCount: controller.soruList.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index ==
                                            controller.soruList.length) {
                                          return GestureDetector(
                                            onTap: controller.addNewQuestion,
                                            child: Container(
                                              height: 70,
                                              alignment: Alignment.center,
                                              color: Colors.green,
                                              child: const Padding(
                                                padding: EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Icon(
                                                  Icons.add_rounded,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            CreateTestQuestionContent(
                                              model: controller.soruList[index],
                                              testID: controller.testID,
                                              index: index,
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  controller.deleteQuestion(
                                                index,
                                              ),
                                              child: Transform.translate(
                                                offset: const Offset(-7, 7),
                                                child: Container(
                                                  width: 70,
                                                  height: 30,
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(
                                                        40,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                    ),
                                                    child: Text(
                                                      "common.delete".tr,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratBold",
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                            GestureDetector(
                              onTap: controller.publishTest,
                              child: Container(
                                height: 50,
                                color: Colors.purple,
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "post_creator.publish".tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
