import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/Buttons/ScrollToTopButton.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/AnswerKeyContent.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormContent/OpticalFormContent.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticsAndBooksPublished/OpticsAndBooksPublishedController.dart';

class OpticsAndBooksPublished extends StatelessWidget {
  OpticsAndBooksPublished({super.key});

  final controller = Get.put(OpticsAndBooksPublishedController());
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      controller.scrollOffset.value = _scrollController.offset;
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          Column(
            children: [
              BackButtons(text: "Yayınladıklarım"),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setSelection(0),
                      child: Obx(
                        () => Container(
                          height: 40,
                          alignment: Alignment.center,
                          color: controller.selection.value == 0
                              ? Colors.blueAccent
                              : Colors.grey.withAlpha(20),
                          child: Text(
                            "Kitap (${controller.list.length})",
                            style: TextStyle(
                              color: controller.selection.value == 0
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setSelection(1),
                      child: Obx(
                        () => Container(
                          height: 40,
                          alignment: Alignment.center,
                          color: controller.selection.value == 1
                              ? Colors.blueAccent
                              : Colors.grey.withAlpha(20),
                          child: Text(
                            "Optik Form (${controller.optikler.length})",
                            style: TextStyle(
                              color: controller.selection.value == 1
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Obx(
                    () => controller.isLoading.value
                        ? Center(
                            child: CupertinoActivityIndicator(),
                          )
                        : controller.selection.value == 0
                            ? Padding(
                                padding: EdgeInsets.all(15),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 5.0,
                                    mainAxisSpacing: 5.0,
                                    childAspectRatio: 2.7 / 5.4,
                                  ),
                                  itemCount: controller.list.length,
                                  itemBuilder: (context, index) {
                                    final item = controller.list[index];
                                    return AnswerKeyContent(
                                      model: item,
                                      onUpdate: (v) => controller.getData(),
                                    );
                                  },
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: controller.optikler.length,
                                itemBuilder: (context, index) {
                                  return OpticalFormContent(
                                    model: controller.optikler[index],
                                    update: () => controller.getOptikler(),
                                  );
                                },
                              ),
                  ),
                ),
              ),
            ],
          ),
          ScrollTotopButton(
            scrollController: _scrollController,
            visibilityThreshold: 350,
          ),
        ]),
      ),
    );
  }
}
