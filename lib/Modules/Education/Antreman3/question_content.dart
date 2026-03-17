import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/full_screen_image_viewer.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanScore/antreman_score.dart';
import 'package:turqappv2/Modules/Education/Antreman3/Complaint/complaint.dart';
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/then_solve.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class QuestionContent extends StatelessWidget {
  QuestionContent({super.key});

  final AntremanController controller = Get.find<AntremanController>();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final ScrollController _scrollController = ScrollController();

  int _fallbackAntPoint() {
    final current = CurrentUserService.instance.currentUser;
    if (current?.userID == controller.userID) {
      return current?.antPoint ?? 100;
    }
    return 100;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onScreenReEnter();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          controller.loadingProgress.value >= 1.0) {
        controller.fetchMoreQuestions();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.onScreenReEnter();
        Get.back();
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
                        child: BackButtons(text: "Soru Bankası"),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => AntremanScore());
                      },
                      child: Row(
                        children: [
                          StreamBuilder<int?>(
                            stream: _antremanRepository.scoreStream(
                              controller.userID,
                            ),
                            builder: (context, snapshot) {
                              final antPoint = snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data == null
                                  ? _fallbackAntPoint()
                                  : snapshot.data!;
                              return Text(
                                antPoint.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 25,
                                  fontFamily: "MontserratMedium",
                                ),
                              );
                            },
                          ),
                          Image.asset(
                            "assets/icons/trophy.webp",
                            color: Colors.black,
                            height: 25,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.savedQuestionsList.clear();
                        controller.fetchSavedQuestions();
                        Get.to(() => ThenSolve());
                      },
                      icon: Image.asset(
                        'assets/icons/reshare.webp',
                        width: 24,
                        height: 24,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.loadingProgress.value < 0.5) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Sorular Yükleniyor...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: LinearProgressIndicator(
                                value: controller.loadingProgress.value,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (controller.questions.isEmpty) {
                      return Center(child: Text("Soru bulunamadı!"));
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 1000,
                      itemCount: controller.questions.length + 1,
                      itemBuilder: (context, index) {
                        if (index == controller.questions.length) {
                          return Obx(() {
                            if (controller.loadingProgress.value < 1.0) {
                              return Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          });
                        }

                        final question = controller.questions[index];
                        final aspectRatio =
                            controller.imageAspectRatios[question.soru] ?? 1.0;

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
                                    controller.getRandomColor(
                                      controller.subjects[question.anaBaslik]
                                                  ?[question.sinavTuru]
                                              ?.indexOf(question.ders) ??
                                          0,
                                    ),
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
                                  Expanded(
                                    child: Text(
                                      "${index + 1}. Soru ${question.ders} (${question.sinavTuru == question.anaBaslik ? question.anaBaslik : "${question.sinavTuru} - ${question.anaBaslik}"})",
                                      style: TextStyles.bold18Black,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Get.bottomSheet(
                                        ComplaintBottomSheet(
                                            question: question),
                                        isScrollControlled: true,
                                      );
                                    },
                                    icon: const Icon(
                                      CupertinoIcons.ellipsis_vertical,
                                      color: Colors.black,
                                      size: 20,
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
                                  controller.selectedAnswers[question.docID] ??
                                      '';
                              final initialAnswer =
                                  controller.initialAnswers[question.docID] ??
                                      '';
                              final isInitialCorrect =
                                  initialAnswer.isNotEmpty &&
                                      initialAnswer == question.dogruCevap;
                              final isSaved =
                                  controller.savedQuestions[question.docID] ??
                                      false;
                              // LGS için şık sayısını 4 ile sınırlandır (A, B, C, D)
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
                                      containerColor =
                                          Colors.black; // Diğer şıklar siyah
                                      textColor = Colors.white; // Harfler beyaz
                                    }
                                  }

                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: GestureDetector(
                                        onTap: (selectedAnswer.isNotEmpty ||
                                                isSaved)
                                            ? null
                                            : () {
                                                controller.submitAnswer(
                                                  option,
                                                  question,
                                                );
                                              },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          width: 50,
                                          decoration: BoxDecoration(
                                            color: containerColor,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            boxShadow: isSaved
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.8),
                                                      blurRadius: 12,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Opacity(
                                            opacity: isSaved ? 0.5 : 1.0,
                                            child: Text(
                                              option,
                                              style: TextStyles.questionChar
                                                  .copyWith(color: textColor),
                                            ),
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
                                                      question.docID] ??
                                                  false
                                              ? CupertinoIcons
                                                  .hand_thumbsup_fill
                                              : CupertinoIcons.hand_thumbsup,
                                        ),
                                        color: controller.likedQuestions[
                                                    question.docID] ??
                                                false
                                            ? Colors.black
                                            : Colors.black,
                                        onPressed: () => controller.addTolikes(
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
                                Obx(
                                  () {
                                    final hasAnswered =
                                        (controller.selectedAnswers[
                                                    question.docID] ??
                                                '')
                                            .isNotEmpty;
                                    return Row(
                                      children: [
                                        IconButton(
                                          icon:
                                              Icon(CupertinoIcons.bubble_left),
                                          color: hasAnswered
                                              ? Colors.black
                                              : Colors.grey,
                                          onPressed: () {
                                            if (hasAnswered) {
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
                                        StreamBuilder<int>(
                                          stream: _antremanRepository
                                              .commentCountStream(
                                            question.docID,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "${snapshot.data}",
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
                                    );
                                  },
                                ),
                                Obx(
                                  () => Row(
                                    children: [
                                      IconButton(
                                        onPressed: controller
                                                    .selectedAnswers[
                                                        question.docID]
                                                    ?.isNotEmpty ??
                                                false
                                            ? null
                                            : () => controller
                                                .addToSonraCoz(question),
                                        icon: Image.asset(
                                          'assets/icons/reshare.webp',
                                          color: controller.savedQuestions[
                                                      question.docID] ??
                                                  false
                                              ? Colors.black
                                              : Colors.black,
                                          width:
                                              24, // İsteğe bağlı boyutlandırma
                                          height: 24,
                                        ),
                                      ),
                                      Text("Sonra Çöz"),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(AppIcons.share, size: 20),
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
              visibilityThreshold: 500,
            ),
          ]),
        ),
      ),
    );
  }
}
