part of 'question_content.dart';

extension QuestionContentShellContentPart on QuestionContent {
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              controller.onScreenReEnter();
              Get.back();
            },
            child: BackButtons(text: 'training.question_bank_title'.tr),
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
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'training.questions_loading'.tr,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontFamily: 'MontserratMedium',
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: LinearProgressIndicator(
              value: controller.loadingProgress.value,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList(BuildContext context) {
    final adCount = controller.questions.length ~/ 3;
    final contentCount = controller.questions.length + adCount;

    return ListView.builder(
      controller: _scrollController,
      physics: AlwaysScrollableScrollPhysics(),
      cacheExtent: 1000,
      itemCount: contentCount + 1,
      itemBuilder: (context, index) {
        if (index == contentCount) {
          return Obx(() {
            if (controller.loadingProgress.value < 1.0) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return SizedBox.shrink();
          });
        }

        if ((index + 1) % 4 == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: AdmobKare(
                suggestionPlacementId: 'answer_key',
              ),
            ),
          );
        }

        final questionIndex = index - ((index + 1) ~/ 4);
        return _buildQuestionItem(context, questionIndex);
      },
    );
  }
}
