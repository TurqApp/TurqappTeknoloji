import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/Buttons/ScrollToTopButton.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Core/FullScreenImageViewer.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/AntremanComments.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanController.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanScore/AntremanScore.dart';
import 'package:turqappv2/Modules/Education/Antreman3/Complaint/Complaint.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

class ThenSolve extends StatelessWidget {
  ThenSolve({super.key});

  final AntremanController controller = Get.find<AntremanController>();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.onScreenReEnter();
        Get.back();
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.onScreenReEnter();
                          Get.back();
                        },
                        child: BackButtons(text: "Sonra Çöz"),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(AntremanScore()),
                      child: Row(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(controller.userID)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  snapshot.hasError ||
                                  !snapshot.hasData ||
                                  !snapshot.data!.exists) {
                                return Text("0");
                              }
                              int antPoint = snapshot.data!['antPoint'] ?? 0;
                              return Text(
                                antPoint.toString(),
                                style: TextStyles.textFieldTitle,
                              );
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
                  child: Obx(() {
                    if (controller.loadingProgress.value < 0.5) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(),
                            10.ph,
                            Text(
                              "Sorular Yükleniyor...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final savedQuestions = controller.savedQuestionsList;

                    if (savedQuestions.isEmpty) {
                      return EmptyRow(
                        text: 'Sonra Çözülecek soru bulunamadı!',
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 1000,
                      itemCount: savedQuestions.length,
                      itemBuilder: (context, index) {
                        final question = savedQuestions[index];
                        final aspectRatio =
                            controller.imageAspectRatios[question.soru] ?? 1.0;
                        final subjectIndex = controller
                                .subjects[question.anaBaslik]
                                    ?[question.sinavTuru]
                                ?.indexOf(question.ders) ??
                            0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.only(left: 16),
                              alignment: Alignment.centerLeft,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    controller.getRandomColor(subjectIndex),
                                    Colors.white,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${index + 1}. Soru ${question.sinavTuru} - ${question.ders}",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  PullDownButton(
                                    itemBuilder: (context) => [
                                      PullDownMenuItem(
                                        title: 'Bildir',
                                        icon: AppIcons.info,
                                        onTap: () {
                                          Get.bottomSheet(
                                            ComplaintBottomSheet(
                                                question: question),
                                            isScrollControlled: true,
                                          );
                                        },
                                      ),
                                      PullDownMenuItem(
                                        title: 'Sonra Çözden Kaldır',
                                        icon: AppIcons.delete,
                                        onTap: () async {
                                          await controller
                                              .addToSonraCoz(question);
                                          if (!controller
                                              .savedQuestions[question.soru]!) {
                                            controller.savedQuestionsList
                                                .remove(question);
                                          }
                                        },
                                      ),
                                    ],
                                    buttonBuilder: (context, showMenu) =>
                                        IconButton(
                                      onPressed: showMenu,
                                      icon: Icon(
                                        CupertinoIcons.ellipsis_vertical,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () => FullScreenImageViewer(
                                        imageUrl: question.soru,
                                      ),
                                    );
                                  },
                                  child: PinchZoom(
                                    child: CachedNetworkImage(
                                      imageUrl: question.soru,
                                      placeholder: (context, url) =>
                                          AspectRatio(
                                        aspectRatio: aspectRatio,
                                        child: Container(
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: CupertinoActivityIndicator(),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          AspectRatio(
                                        aspectRatio: aspectRatio,
                                        child: Container(
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Obx(() {
                              final selectedAnswer =
                                  controller.selectedAnswers[question.soru] ??
                                      '';
                              final initialAnswer =
                                  controller.initialAnswers[question.soru] ??
                                      '';
                              final isInitialCorrect =
                                  initialAnswer.isNotEmpty &&
                                      initialAnswer == question.dogruCevap;
                              final int optionCount =
                                  question.sinavTuru == "LGS"
                                      ? 4
                                      : question.kacCevap.toInt();

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(optionCount, (i) {
                                  final option = String.fromCharCode(65 + i);
                                  Color containerColor = Colors.grey;
                                  Color textColor = Colors.white;

                                  if (initialAnswer.isNotEmpty) {
                                    if (option == initialAnswer) {
                                      containerColor = (isInitialCorrect ||
                                              option == question.dogruCevap)
                                          ? Colors.green
                                          : Colors.red;
                                    } else if (option == question.dogruCevap) {
                                      containerColor = Colors.green;
                                    } else {
                                      containerColor = Colors.black;
                                      textColor = Colors.white;
                                    }
                                  }

                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: GestureDetector(
                                        onTap: selectedAnswer.isNotEmpty
                                            ? null
                                            : () => controller.submitAnswer(
                                                  option,
                                                  question,
                                                ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          width: 50,
                                          decoration: BoxDecoration(
                                            color: containerColor,
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                          child: Text(
                                            option,
                                            style: TextStyles.questionChar
                                                .copyWith(color: textColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Obx(
                                  () => Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          controller.likedQuestions[
                                                      question.soru] ??
                                                  false
                                              ? CupertinoIcons
                                                  .hand_thumbsup_fill
                                              : CupertinoIcons.hand_thumbsup,
                                        ),
                                        color: controller.likedQuestions[
                                                    question.soru] ??
                                                false
                                            ? Colors.blue
                                            : Colors.black,
                                        onPressed: () =>
                                            controller.addTolikes(
                                          question,
                                        ),
                                      ),
                                      Text(
                                        "${question.begeniler.length}",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.bubble_left,
                                      ),
                                      color: controller
                                                  .selectedAnswers[
                                                      question.soru]
                                                  ?.isNotEmpty ??
                                              false
                                          ? Colors.black
                                          : Colors.grey,
                                      onPressed: () {
                                        if (controller
                                                .selectedAnswers[question.soru]
                                                ?.isNotEmpty ??
                                            false) {
                                          Get.bottomSheet(
                                            AntremanComments(
                                                question: question),
                                            isScrollControlled: true,
                                          );
                                        } else {
                                          AppSnackbar(
                                            "Bilgi",
                                            "Önce soruyu cevaplayın!",
                                          );
                                        }
                                      },
                                    ),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('SoruBankasi')
                                          .doc(question.docID)
                                          .collection('Yorumlar')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          int commentCount =
                                              snapshot.data!.docs.length;
                                          return Text(
                                            "$commentCount",
                                            style: TextStyle(fontSize: 14),
                                          );
                                        }
                                        return Text(
                                          "0",
                                          style: TextStyle(fontSize: 14),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Obx(
                                  () => Row(
                                    children: [
                                      IconButton(
                                        icon: Image.asset(
                                          'assets/icons/reshare.webp',
                                          width: 24,
                                          height: 24,
                                          color: controller.savedQuestions[
                                                      question.soru] ??
                                                  false
                                              ? Colors.blue
                                              : Colors.black,
                                        ),
                                        color: controller.savedQuestions[
                                                    question.soru] ??
                                                false
                                            ? Colors.blue
                                            : Colors.black,
                                        onPressed: controller
                                                    .selectedAnswers[
                                                        question.soru]
                                                    ?.isNotEmpty ??
                                                false
                                            ? null
                                            : () async {
                                                await controller
                                                    .addToSonraCoz(question);
                                                if (!controller.savedQuestions[
                                                    question.soru]!) {
                                                  controller.savedQuestionsList
                                                      .remove(question);
                                                }
                                              },
                                      ),
                                      Text("Sonra Çöz"),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.paperplane,
                                        size: 20,
                                      ),
                                      color: Colors.black,
                                      onPressed: () =>
                                          controller.addToPaylasanlar(
                                        question,
                                      ),
                                    ),
                                    Text("Paylaş"),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
          ]),
        ),
      ),
    );
  }
}
