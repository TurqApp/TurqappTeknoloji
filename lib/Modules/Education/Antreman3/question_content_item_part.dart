part of 'question_content.dart';

extension QuestionContentItemPart on QuestionContent {
  Widget _buildQuestionItem(BuildContext context, int questionIndex) {
    final question = controller.questions[questionIndex];
    final aspectRatio = controller.imageAspectRatios[question.soru] ?? 1.0;

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
                  controller.subjects[question.anaBaslik]?[question.sinavTuru]
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${questionIndex + 1}. Soru ${question.ders} (${question.sinavTuru == question.anaBaslik ? question.anaBaslik : "${question.sinavTuru} - ${question.anaBaslik}"})',
                  style: TextStyles.bold18Black,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                onPressed: () {
                  Get.bottomSheet(
                    ComplaintBottomSheet(question: question),
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
                  () => FullScreenImageViewer(imageUrl: question.soru),
                );
              },
              child: PinchZoom(
                child: CachedNetworkImage(
                  imageUrl: question.soru,
                  placeholder: (context, url) => AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  ),
                  errorWidget: (context, url, error) => AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: Center(child: Icon(Icons.error)),
                    ),
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        _buildAnswerOptions(question),
        SizedBox(height: 10),
        _buildQuestionActions(question),
      ],
    );
  }

  Widget _buildAnswerOptions(dynamic question) {
    return Obx(() {
      final selectedAnswer = controller.selectedAnswers[question.docID] ?? '';
      final initialAnswer = controller.initialAnswers[question.docID] ?? '';
      final isInitialCorrect =
          initialAnswer.isNotEmpty && initialAnswer == question.dogruCevap;
      final isSaved = controller.savedQuestions[question.docID] ?? false;
      final int optionCount = question.sinavTuru == _antremanLgsType
          ? 4
          : question.kacCevap.toInt();

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(optionCount, (i) {
          final option = String.fromCharCode(65 + i);
          Color containerColor = Colors.grey;
          Color textColor = Colors.white;

          if (initialAnswer.isNotEmpty) {
            if (option == initialAnswer) {
              containerColor =
                  (isInitialCorrect || option == question.dogruCevap)
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
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: GestureDetector(
                onTap: (selectedAnswer.isNotEmpty || isSaved)
                    ? null
                    : () {
                        controller.submitAnswer(option, question);
                      },
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: isSaved
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.8),
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
                      style: TextStyles.questionChar.copyWith(color: textColor),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildQuestionActions(dynamic question) {
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      runSpacing: 4,
      spacing: 12,
      children: [
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  controller.likedQuestions[question.docID] ?? false
                      ? CupertinoIcons.hand_thumbsup_fill
                      : CupertinoIcons.hand_thumbsup,
                ),
                color: Colors.black,
                onPressed: () => controller.addTolikes(question),
              ),
              Text('${question.begeniler.length}',
                  style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        Obx(() {
          final hasAnswered =
              (controller.selectedAnswers[question.docID] ?? '').isNotEmpty;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(CupertinoIcons.bubble_left),
                color: hasAnswered ? Colors.black : Colors.grey,
                onPressed: () {
                  if (hasAnswered) {
                    Get.bottomSheet(
                      AntremanComments(question: question),
                      isScrollControlled: true,
                    );
                  } else {
                    AppSnackbar('common.info'.tr, 'training.answer_first'.tr);
                  }
                },
              ),
              StreamBuilder<int>(
                stream: _antremanRepository.commentCountStream(question.docID),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('${snapshot.data}',
                        style: TextStyle(fontSize: 14));
                  }
                  return Text('0', style: TextStyle(fontSize: 14));
                },
              ),
            ],
          );
        }),
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed:
                    controller.selectedAnswers[question.docID]?.isNotEmpty ??
                            false
                        ? null
                        : () => controller.addToSonraCoz(question),
                icon: Image.asset(
                  'assets/icons/reshare.webp',
                  color: Colors.black,
                  width: 24,
                  height: 24,
                ),
              ),
              Text('pasaj.question_bank.solve_later'.tr),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(AppIcons.share, size: 20),
              color: Colors.black,
              onPressed: () => controller.addToPaylasanlar(question),
            ),
            Text('training.share'.tr),
          ],
        ),
      ],
    );
  }
}
