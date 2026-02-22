import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSorusuHazirla/SinavSorusuHazirlaController.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SoruContent/SoruContent.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SoruModel.dart';

class SinavSorusuHazirla extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = Get.put(
      SinavSorusuHazirlaController(
        docID: docID,
        sinavTuru: sinavTuru,
        tumDersler: tumDersler,
        derslerinSoruSayilari: derslerinSoruSayilari,
        complated: complated,
      ),
    );

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
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Bu ders için soru bulunamadı. Lütfen soruları ekleyin veya sınav türünü kontrol edin.",
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
                                sinavTuru: sinavTuru,
                                mainID: docID,
                                index: entry.key,
                                ders: entry.value.ders,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Text(
                                "${entry.key + 1}. Soru",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.grey.withOpacity(0.3)),
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
                BackButtons(text: "Soru Hazırla"),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CupertinoActivityIndicator(radius: 20),
                          )
                        : controller.isInitialized.value &&
                                controller.list.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    "Hiç soru bulunamadı. Lütfen soruları ekleyin veya sınav türünü kontrol edin.",
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
                                        for (var ders in tumDersler)
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
                                              child: const Text(
                                                "Tamamla",
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
