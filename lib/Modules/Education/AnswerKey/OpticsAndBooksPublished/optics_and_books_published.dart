import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormContent/optical_form_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published_controller.dart';

class OpticsAndBooksPublished extends StatelessWidget {
  OpticsAndBooksPublished({super.key});

  final controller = Get.put(OpticsAndBooksPublishedController());
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    controller.refreshOnOpen();

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
                              ? Colors.black
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
                              ? Colors.black
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                    childAspectRatio: 0.45,
                                  ),
                                  itemCount: controller.list.length,
                                  itemBuilder: (context, index) {
                                    final item = controller.list[index];
                                    return AnswerKeyContent(
                                      key: ValueKey(item.docID),
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
