import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test_controller.dart';

class SolveTest extends StatelessWidget {
  final String testID;
  final Function showSucces;

  const SolveTest({super.key, required this.testID, required this.showSucces});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SolveTestController(testID: testID, showSucces: showSucces),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => controller.isLoading.value
              ? Center(
                  child: CupertinoActivityIndicator(),
                )
              : controller.soruList.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(15),
                      child: EmptyRow(
                          text:
                              "Soru bulunamadı.\nBu test için soru yüklenemedi."))
                  : Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: ListView.builder(
                              itemCount: controller.soruList.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return SizedBox(
                                    height: 50,
                                    child: Padding(
                                      padding: EdgeInsets.all(15.0),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              GestureDetector(
                                                onTap: Get.back,
                                                child: SizedBox(
                                                  width: 30,
                                                  height: 30,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.arrow_back,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Obx(
                                                () => Text(
                                                  controller.formatDuration(
                                                    controller
                                                        .elapsedTime.value,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.5,
                                            child: Obx(
                                              () => Text(
                                                controller.fullname.value,
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (index ==
                                    controller.soruList.length + 1) {
                                  return GestureDetector(
                                    onTap: controller.testiBitir,
                                    child: Container(
                                      height: 50,
                                      color: Colors.green,
                                      alignment: Alignment.center,
                                      child: Text("Testi Bitir",
                                          style: TextStyles.medium15white),
                                    ),
                                  );
                                } else {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: Offset(4, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Stack(
                                          alignment: Alignment.topLeft,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 40,
                                                horizontal: 20,
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl: controller
                                                    .soruList[index - 1].img,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child:
                                                      CupertinoActivityIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(
                                                  Icons.broken_image,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(left: 12),
                                              child: Container(
                                                width: 100,
                                                height: 40,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  "${index.toString()}. Soru",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20,
                                                    fontFamily:
                                                        "MontserratBold",
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          height: 50,
                                          color: Colors.pink
                                              .withValues(alpha: 0.2),
                                          alignment: Alignment.center,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 30,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                for (var choice in [
                                                  'A',
                                                  'B',
                                                  'C',
                                                  'D',
                                                  'E',
                                                ])
                                                  GestureDetector(
                                                    onTap: () =>
                                                        controller.updateAnswer(
                                                      index - 1,
                                                      choice,
                                                    ),
                                                    child: Obx(
                                                      () => Container(
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                          vertical: 5,
                                                        ),
                                                        height: 40,
                                                        width: 40,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: controller
                                                                          .cevaplar[
                                                                      index -
                                                                          1] ==
                                                                  choice
                                                              ? Colors.black
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            50,
                                                          ),
                                                          border: Border.all(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          choice,
                                                          style: TextStyle(
                                                            color: controller
                                                                            .cevaplar[
                                                                        index -
                                                                            1] ==
                                                                    choice
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
