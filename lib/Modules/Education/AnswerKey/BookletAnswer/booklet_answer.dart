import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletAnswer/booklet_answer_controller.dart';

class BookletAnswer extends StatelessWidget {
  final AnswerKeySubModel model;
  final BookletModel anaModel;

  const BookletAnswer({required this.model, required this.anaModel, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BookletAnswerController(model, anaModel));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                _buildHeader(context, controller),
                Expanded(child: _buildQuestionList(context, controller)),
              ],
            ),
            _buildResultDialog(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    BookletAnswerController controller,
  ) {
    return Row(children: [BackButtons(text: controller.model.baslik)]);
  }

  Widget _buildQuestionList(
    BuildContext context,
    BookletAnswerController controller,
  ) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemCount: controller.model.dogruCevaplar.length + 1,
        itemBuilder: (context, index) {
          if (index == controller.model.dogruCevaplar.length) {
            return Obx(
              () => controller.cevaplar.any(
                (cevap) => ["A", "B", "C", "D", "E"].contains(cevap),
              )
                  ? GestureDetector(
                      onTap: controller.finishTest,
                      child: Container(
                        height: 50,
                        color: Colors.green,
                        alignment: Alignment.center,
                        child: Text(
                          "tests.finish_test".tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                    )
                  : Container(),
            );
          }

          return QuestionItem(index: index, controller: controller);
        },
      ),
    );
  }

  Widget _buildResultDialog(
    BuildContext context,
    BookletAnswerController controller,
  ) {
    return Obx(
      () => controller.completed.value
          ? Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
                Container(
                  height: (MediaQuery.of(context).size.height * 0.42)
                      .clamp(260.0, 320.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "practice.congrats_title".tr,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 25,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "tests.completed_short".tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                height: 1.4,
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.12),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _resultItem(
                                      "tests.correct".tr,
                                      controller.correctCount.value.toString(),
                                    ),
                                    _resultItem(
                                      "tests.wrong".tr,
                                      controller.wrongCount.value.toString(),
                                    ),
                                    _resultItem(
                                      "tests.blank".tr,
                                      controller.emptyCount.value.toString(),
                                    ),
                                    _resultItem(
                                      "tests.net".tr,
                                      controller.netScore.value
                                          .toStringAsFixed(2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => Text(
                                "${'tests.score'.tr}: ${controller.scorePercent.value.toStringAsFixed(1)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "common.continue".tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Container(),
    );
  }

  Widget _resultItem(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: "MontserratBold",
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontFamily: "MontserratMedium",
          ),
        ),
      ],
    );
  }
}

class QuestionItem extends StatelessWidget {
  final int index;
  final BookletAnswerController controller;

  const QuestionItem({
    required this.index,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: index % 2 == 0 ? 0.2 : 0.4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${index + 1}.",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: "MontserratBold",
              ),
            ),
            for (var item in ["A", "B", "C", "D", "E"])
              Obx(
                () => GestureDetector(
                  onTap: () => controller.updateAnswer(index, item),
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.cevaplar[index] == item
                          ? Colors.black
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: controller.cevaplar[index] == item
                            ? Colors.white
                            : Colors.black,
                        fontSize: 20,
                        fontFamily: "MontserratBold",
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
