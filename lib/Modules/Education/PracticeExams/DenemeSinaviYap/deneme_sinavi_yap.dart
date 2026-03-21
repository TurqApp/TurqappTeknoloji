import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

const _practiceExamLgsType = 'LGS';

class DenemeSinaviYap extends StatefulWidget {
  final SinavModel model;
  final Function sinaviBitir;
  final Function showGecersizAlert;
  final bool uyariAtla;

  const DenemeSinaviYap({
    super.key,
    required this.model,
    required this.sinaviBitir,
    required this.showGecersizAlert,
    required this.uyariAtla,
  });

  @override
  State<DenemeSinaviYap> createState() => _DenemeSinaviYapState();
}

class _DenemeSinaviYapState extends State<DenemeSinaviYap> {
  late final String _tag;
  late final DenemeSinaviYapController controller;
  late final bool _ownsController;

  Widget buildQuestionCard(
    SoruModel soru,
    int index,
    DenemeSinaviYapController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'tests.question_number'
                                  .trParams({'index': index.toString()}),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ],
                        ),
                        CachedNetworkImage(
                          imageUrl: soru.soru,
                          errorWidget: (context, url, error) => Text(
                            'practice.question_image_failed'.tr,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              color: Colors.pinkAccent.withValues(alpha: 0.5),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: (controller.model.sinavTuru == _practiceExamLgsType
                          ? ['A', 'B', 'C', 'D']
                          : ['A', 'B', 'C', 'D', 'E'])
                      .map((option) {
                    final isSelected = controller
                            .selectedAnswers[controller.list.indexOf(soru)] ==
                        option;
                    return GestureDetector(
                      onTap: () {
                        controller.selectedAnswers[
                            controller.list.indexOf(soru)] = option;
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRulesSection(DenemeSinaviYapController controller) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'practice.exam_started_title'.tr,
              style: TextStyle(
                color: Colors.purple,
                fontSize: 25,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(height: 12),
            Text(
              'practice.exam_started_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratMedium",
              ),
            ),
            SizedBox(height: 12),
            Divider(color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'practice.rules_title'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Text(
                    "1-)",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'practice.rule_1'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Text(
                    "2-)",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'practice.rule_2'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Text(
                    "3-)",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'practice.rule_3'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            GestureDetector(
              onTap: () => controller.selection.value = 0,
              child: Container(
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  'practice.start_exam'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tag = 'practice_exam_solve_${widget.model.docID}_${identityHashCode(this)}';
    if (Get.isRegistered<DenemeSinaviYapController>(tag: _tag)) {
      controller = Get.find<DenemeSinaviYapController>(tag: _tag);
      _ownsController = false;
    } else {
      controller = Get.put(
        DenemeSinaviYapController(
          model: widget.model,
          sinaviBitir: widget.sinaviBitir,
          showGecersizAlert: widget.showGecersizAlert,
          uyariAtla: widget.uyariAtla,
        ),
        tag: _tag,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<DenemeSinaviYapController>(tag: _tag) &&
        identical(Get.find<DenemeSinaviYapController>(tag: _tag), controller)) {
      Get.delete<DenemeSinaviYapController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Obx(
              () => controller.selection.value == 0
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BackButtons(text: controller.model.sinavAdi),
                            Padding(
                              padding: EdgeInsets.only(right: 15),
                              child: Obx(
                                () => Text(
                                  controller.fullName.value,
                                  style: TextStyles.textFieldTitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Obx(
                            () => controller.isLoading.value
                                ? Center(
                                    child: CupertinoActivityIndicator(),
                                  )
                                : controller.isInitialized.value &&
                                        controller.list.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.black,
                                                size: 40,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'tests.solve_no_questions'.tr,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : RefreshIndicator(
                                        color: Colors.white,
                                        backgroundColor: Colors.black,
                                        onRefresh: controller.refreshData,
                                        child: ListView(
                                          children: [
                                            Column(
                                              children: [
                                                for (var ders
                                                    in controller.model.dersler)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (controller.list
                                                          .where(
                                                            (soru) =>
                                                                soru.ders ==
                                                                ders,
                                                          )
                                                          .isNotEmpty)
                                                        Container(
                                                          height: 50,
                                                          alignment:
                                                              Alignment.center,
                                                          color: Colors.indigo,
                                                          child: Text(
                                                            ders,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 18,
                                                              fontFamily:
                                                                  "MontserratMedium",
                                                            ),
                                                          ),
                                                        ),
                                                      ...(() {
                                                        int counter = 1;
                                                        return controller.list
                                                            .where(
                                                          (soru) =>
                                                              soru.ders == ders,
                                                        )
                                                            .map((soru) {
                                                          final index =
                                                              counter++;
                                                          return buildQuestionCard(
                                                            soru,
                                                            index,
                                                            controller,
                                                          );
                                                        }).toList();
                                                      })(),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: controller.setData,
                                              child: Container(
                                                height: 50,
                                                alignment: Alignment.center,
                                                color: Colors.green,
                                                child: Text(
                                                  'practice.finish_exam'.tr,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratBold",
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
                    )
                  : buildRulesSection(controller),
            ),
          ],
        ),
      ),
    );
  }
}
