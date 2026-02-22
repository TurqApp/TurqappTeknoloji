import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/ActionButton.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanController.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanScore/AntremanScore.dart';
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/ThenSolve.dart';
import 'package:turqappv2/Modules/TypeWriter/TypeWriter.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

class AntremanView2 extends StatelessWidget {
  AntremanView2({super.key});

  final AntremanController controller = Get.put(AntremanController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Icon(
                          AppIcons.arrowLeft,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                      TypewriterText(
                        text: "Çöz Geç",
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(() => AntremanScore());
                  },
                  child: Row(
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(controller.userID)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text("0");
                          } else if (snapshot.hasError) {
                            return const Text("0");
                          } else if (!snapshot.hasData ||
                              !snapshot.data!.exists) {
                            return const Text("0");
                          } else {
                            int antPoint = snapshot.data!['antPoint'];
                            return Text(
                              antPoint.toString(),
                              style: TextStyles.bold20Black,
                            );
                          }
                        },
                      ),
                      Image.asset(
                        "assets/icons/trophy.webp",
                        height: 25,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                15.pw
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: ListView.builder(
                  itemCount: controller.subjects.keys.length,
                  itemBuilder: (context, index) {
                    String anaBaslik =
                        controller.subjects.keys.elementAt(index);
                    Color titleColor = Colors.white;

                    return Obx(() => Column(
                          key: Key(anaBaslik),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (controller.expandedIndex.value == index) {
                                  controller.expandedIndex.value = -1;
                                } else {
                                  controller.expandedIndex.value = index;
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(15),
                                margin: EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: controller.getRandomColor(index),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        anaBaslik,
                                        style: TextStyles.antremanTitle,
                                      ),
                                    ),
                                    Icon(
                                      controller.expandedIndex.value == index
                                          ? AppIcons.up
                                          : AppIcons.down,
                                      color: titleColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              height: controller.expandedIndex.value == index
                                  ? null
                                  : 0,
                              child: controller.expandedIndex.value == index
                                  ? Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: List.generate(
                                          controller
                                              .subjects[anaBaslik]!.keys.length,
                                          (sinavIndex) {
                                            String sinavTuru = controller
                                                .subjects[anaBaslik]!.keys
                                                .elementAt(sinavIndex);
                                            List<String> dersler =
                                                controller.subjects[anaBaslik]![
                                                    sinavTuru]!;

                                            // Eğer anaBaslik ve sinavTuru aynıysa, doğrudan dersleri göster
                                            if (anaBaslik == sinavTuru) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: List.generate(
                                                  dersler.length,
                                                  (dersIndex) {
                                                    final ders =
                                                        dersler[dersIndex];
                                                    return GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: () {
                                                        controller
                                                            .selectSubject(
                                                          ders,
                                                          anaBaslik,
                                                          sinavTuru,
                                                        );
                                                      },
                                                      child: Container(
                                                        width: double.infinity,
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                                vertical: 5),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  ders,
                                                                  style: TextStyles
                                                                      .textFieldTitle,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                Icon(
                                                                  CupertinoIcons
                                                                      .chevron_right,
                                                                  size: 20,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                              ],
                                                            ),
                                                            if (dersIndex <
                                                                dersler.length -
                                                                    1)
                                                              appDivider(),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            } else {
                                              // anaBaslik ve sinavTuru farklıysa, iç içe bir AnimatedContainer kullan
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (controller
                                                              .expandedSubIndex
                                                              .value ==
                                                          sinavIndex) {
                                                        controller
                                                            .expandedSubIndex
                                                            .value = -1;
                                                      } else {
                                                        controller
                                                            .expandedSubIndex
                                                            .value = sinavIndex;
                                                      }
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      margin:
                                                          EdgeInsets.symmetric(
                                                              vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade200,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            sinavTuru,
                                                            style: TextStyles
                                                                .bold18Black,
                                                          ),
                                                          Icon(
                                                            controller.expandedSubIndex
                                                                        .value ==
                                                                    sinavIndex
                                                                ? AppIcons.up
                                                                : AppIcons.down,
                                                            color:
                                                                Colors.black87,
                                                            size: 18,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: Duration(
                                                        milliseconds: 300),
                                                    curve: Curves.easeInOut,
                                                    height: controller
                                                                .expandedSubIndex
                                                                .value ==
                                                            sinavIndex
                                                        ? null
                                                        : 0,
                                                    child: controller
                                                                .expandedSubIndex
                                                                .value ==
                                                            sinavIndex
                                                        ? Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                            child: Column(
                                                              children:
                                                                  List.generate(
                                                                dersler.length,
                                                                (dersIndex) {
                                                                  final ders =
                                                                      dersler[
                                                                          dersIndex];
                                                                  return GestureDetector(
                                                                    behavior:
                                                                        HitTestBehavior
                                                                            .opaque,
                                                                    onTap: () {
                                                                      controller
                                                                          .selectSubject(
                                                                        ders,
                                                                        anaBaslik,
                                                                        sinavTuru,
                                                                      );
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      margin: EdgeInsets.symmetric(
                                                                          vertical:
                                                                              5),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                ders,
                                                                                style: TextStyles.textFieldTitle,
                                                                                textAlign: TextAlign.center,
                                                                              ),
                                                                              Icon(
                                                                                CupertinoIcons.chevron_right,
                                                                                color: Colors.black87,
                                                                                size: 20,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          if (dersIndex <
                                                                              dersler.length - 1)
                                                                            appDivider(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          )
                                                        : SizedBox.shrink(),
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    )
                                  : SizedBox.shrink(),
                            ),
                          ],
                        ));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ActionButton(
        context: context,
        menuItems: [
          PullDownMenuItem(
            title: 'Puan Tablosu',
            icon: AppIcons.question,
            onTap: () {
              Get.to(() => AntremanScore());
            },
          ),
          PullDownMenuItem(
            title: 'Sonra Çöz',
            icon: CupertinoIcons.repeat,
            onTap: () {
              controller.fetchSavedQuestions();
              Get.to(() => ThenSolve());
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
