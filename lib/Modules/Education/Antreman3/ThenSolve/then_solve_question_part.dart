part of 'then_solve.dart';

extension _ThenSolveQuestionPart on ThenSolve {
  Widget _buildQuestionCard(
    BuildContext context,
    dynamic question, {
    required int index,
  }) {
    final aspectRatio = controller.imageAspectRatios[question.soru] ?? 1.0;
    final subjectIndex = controller.subjects[question.anaBaslik]
                ?[question.sinavTuru]
            ?.indexOf(question.ders) ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionHeader(
          question,
          index: index,
          subjectIndex: subjectIndex,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                  placeholder: (context, url) => AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
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
        const SizedBox(height: 12),
        _buildAnswerOptions(question),
        const SizedBox(height: 10),
        _buildQuestionActions(question),
      ],
    );
  }

  Widget _buildQuestionHeader(
    dynamic question, {
    required int index,
    required int subjectIndex,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      alignment: Alignment.centerLeft,
      width: double.infinity,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${'tests.question_number'.trParams({
                  'index': '${index + 1}'
                })} ${question.sinavTuru} - ${question.ders}',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontFamily: "MontserratBold",
            ),
          ),
          PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuItem(
                title: 'training.report'.tr,
                icon: AppIcons.info,
                onTap: () {
                  Get.bottomSheet(
                    ComplaintBottomSheet(question: question),
                    isScrollControlled: true,
                  );
                },
              ),
              PullDownMenuItem(
                title: 'training.remove_solve_later'.tr,
                icon: AppIcons.delete,
                onTap: () => _removeFromSolveLater(question),
              ),
            ],
            buttonBuilder: (context, showMenu) => IconButton(
              onPressed: showMenu,
              icon: const Icon(
                CupertinoIcons.ellipsis_vertical,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(dynamic question) {
    return Obx(() {
      final selectedAnswer = controller.selectedAnswers[question.docID] ?? '';
      final initialAnswer = controller.initialAnswers[question.docID] ?? '';
      final isInitialCorrect =
          initialAnswer.isNotEmpty && initialAnswer == question.dogruCevap;
      final optionCount = question.sinavTuru == _thenSolveLgsType
          ? 4
          : question.kacCevap.toInt();

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(optionCount, (i) {
          final option = String.fromCharCode(65 + i);
          var containerColor = Colors.grey;
          var textColor = Colors.white;

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
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GestureDetector(
                onTap: selectedAnswer.isNotEmpty
                    ? null
                    : () => controller.submitAnswer(option, question),
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    option,
                    style: TextStyles.questionChar.copyWith(color: textColor),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Obx(
          () => Row(
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
              Text(
                "${question.begeniler.length}",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.bubble_left),
              color: controller.selectedAnswers[question.docID]?.isNotEmpty ??
                      false
                  ? Colors.black
                  : Colors.grey,
              onPressed: () {
                if (controller.selectedAnswers[question.docID]?.isNotEmpty ??
                    false) {
                  Get.bottomSheet(
                    AntremanComments(question: question),
                    isScrollControlled: true,
                  );
                } else {
                  AppSnackbar(
                    "common.info".tr,
                    "training.answer_first".tr,
                  );
                }
              },
            ),
            StreamBuilder<int>(
              stream: _antremanRepository.commentCountStream(question.docID),
              builder: (context, snapshot) {
                final commentCount = snapshot.data ?? 0;
                return Text(
                  "$commentCount",
                  style: const TextStyle(fontSize: 14),
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
                  color: Colors.black,
                ),
                color: Colors.black,
                onPressed:
                    controller.selectedAnswers[question.docID]?.isNotEmpty ??
                            false
                        ? null
                        : () => _removeFromSolveLater(question),
              ),
              Text("pasaj.question_bank.solve_later".tr),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                AppIcons.share,
                size: 20,
              ),
              color: Colors.black,
              onPressed: () => controller.addToPaylasanlar(question),
            ),
            Text("training.share".tr),
          ],
        ),
      ],
    );
  }
}
