import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultContent/booklet_result_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/ResultsAndAnswers/results_and_answers.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results_controller.dart';

class MyBookletResults extends StatelessWidget {
  const MyBookletResults({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyBookletResultsController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Sonuçlarım"),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setSelection(0),
                    child: Obx(
                      () => Container(
                        height: 45,
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
                        height: 45,
                        alignment: Alignment.center,
                        color: controller.selection.value == 1
                            ? Colors.blueAccent
                            : Colors.grey.withAlpha(20),
                        child: Text(
                          "Optik Form",
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
            Obx(
              () => controller.list.isNotEmpty &&
                      controller.selection.value == 0
                  ? Expanded(
                      child: Container(
                        color: Colors.white,
                        child: ListView.builder(
                          itemCount: controller.list.length,
                          itemBuilder: (context, index) {
                            final item = controller.list[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 15 : 0,
                              ),
                              child: BookletResultContent(model: item),
                            );
                          },
                        ),
                      ),
                    )
                  : controller.list.isEmpty && controller.selection.value == 0
                      ? Expanded(
                          child: Container(
                            color: Colors.white,
                            child: const Padding(
                              padding: EdgeInsets.only(top: 15),
                              child: Row(
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
                                        "Her hangi kitapçık çözmedin",
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
                            ),
                          ),
                        )
                      : controller.optikSonuclari.isNotEmpty &&
                              controller.selection.value == 1
                          ? Expanded(
                              child: Container(
                                color: Colors.white,
                                child: ListView.builder(
                                  itemCount: controller.optikSonuclari.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => ResultsAndAnswers(
                                            model: controller
                                                .optikSonuclari[index],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      controller
                                                          .optikSonuclari[index]
                                                          .name,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratBold",
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    controller
                                                                .optikSonuclari[
                                                                    index]
                                                                .bitis <
                                                            DateTime.now()
                                                                .millisecondsSinceEpoch
                                                        ? "Sınav Bitti"
                                                        : controller
                                                                    .optikSonuclari[
                                                                        index]
                                                                    .baslangic
                                                                    .toInt() <
                                                                DateTime.now()
                                                                    .millisecondsSinceEpoch
                                                            ? "Sınav Başladı"
                                                            : "Sınav Başlamadı",
                                                    style: TextStyle(
                                                      color: controller
                                                                  .optikSonuclari[
                                                                      index]
                                                                  .bitis <
                                                              DateTime.now()
                                                                  .millisecondsSinceEpoch
                                                          ? Colors.red
                                                          : controller
                                                                      .optikSonuclari[
                                                                          index]
                                                                      .baslangic
                                                                      .toInt() <
                                                                  DateTime.now()
                                                                      .millisecondsSinceEpoch
                                                              ? Colors.green
                                                              : Colors.black,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratMedium",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Toplam ${controller.optikSonuclari[index].cevaplar.length.toString()} Soru",
                                                        style: const TextStyle(
                                                          color: Colors.indigo,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              "MontserratMedium",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text: controller
                                                              .optikSonuclari[
                                                                  index]
                                                              .docID,
                                                        ),
                                                      );
                                                      AppSnackbar("Başarılı",
                                                          "ID Kopyalandı");
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "ID: ${controller.optikSonuclari[index].docID}",
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'MontserratMedium',
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        const Icon(
                                                          Icons.copy,
                                                          color: Colors.black,
                                                          size: 15,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    timeAgo(
                                                      int.parse(
                                                        controller
                                                            .optikSonuclari[
                                                                index]
                                                            .docID,
                                                      ),
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          'MontserratMedium',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          : const Expanded(child: SizedBox()),
            ),
          ],
        ),
      ),
    );
  }
}
