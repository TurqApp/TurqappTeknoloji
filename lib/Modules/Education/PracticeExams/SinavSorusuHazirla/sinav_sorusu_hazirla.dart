import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSorusuHazirla/sinav_sorusu_hazirla_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SoruContent/soru_content.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

class SinavSorusuHazirla extends StatefulWidget {
  final String docID;
  final String sinavTuru;
  final List<String> tumDersler;
  final List<String> derslerinSoruSayilari;
  final Function() complated;

  const SinavSorusuHazirla({
    super.key,
    required this.docID,
    required this.sinavTuru,
    required this.tumDersler,
    required this.derslerinSoruSayilari,
    required this.complated,
  });

  @override
  State<SinavSorusuHazirla> createState() => _SinavSorusuHazirlaState();
}

class _SinavSorusuHazirlaState extends State<SinavSorusuHazirla> {
  late final String _tag;
  late final SinavSorusuHazirlaController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'practice_question_prepare_${widget.docID}_${identityHashCode(this)}';
    final existing = SinavSorusuHazirlaController.maybeFind(tag: _tag);
    _ownsController = existing == null;
    controller = existing ??
        SinavSorusuHazirlaController.ensure(
          tag: _tag,
          docID: widget.docID,
          sinavTuru: widget.sinavTuru,
          tumDersler: widget.tumDersler,
          derslerinSoruSayilari: widget.derslerinSoruSayilari,
          complated: widget.complated,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          SinavSorusuHazirlaController.maybeFind(tag: _tag),
          controller,
        )) {
      Get.delete<SinavSorusuHazirlaController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildQuestionSection(String ders, List<SoruModel> questions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              color: Colors.indigo,
              child: Text(
                ders,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
            ),
          ),
          questions.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "tests.no_questions_for_lesson".tr,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: questions.asMap().entries.map((entry) {
                    return Column(
                      children: [
                        Stack(
                          alignment: Alignment.topLeft,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: SoruContent(
                                model: entry.value,
                                sinavTuru: widget.sinavTuru,
                                mainID: widget.docID,
                                index: entry.key,
                                ders: entry.value.ders,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Text(
                                'tests.question_number'
                                    .trParams({'index': '${entry.key + 1}'}),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.grey.withValues(alpha: 0.3)),
                      ],
                    );
                  }).toList(),
                ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: 'tests.prepare_questions'.tr),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CupertinoActivityIndicator(radius: 20),
                          )
                        : controller.isInitialized.value &&
                                controller.list.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    "tests.no_questions_at_all".tr,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                color: Colors.white,
                                backgroundColor: Colors.black,
                                onRefresh: controller.getSorular,
                                child: ListView(
                                  children: [
                                    Column(
                                      children: [
                                        for (var ders in widget.tumDersler)
                                          Obx(
                                            () => buildQuestionSection(
                                              ders,
                                              controller.list
                                                  .where(
                                                    (soru) => soru.ders == ders,
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: GestureDetector(
                                            onTap: controller.completeExam,
                                            child: Container(
                                              height: 50,
                                              alignment: Alignment.center,
                                              color: Colors.green,
                                              child: Text(
                                                'tests.complete'.tr,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
