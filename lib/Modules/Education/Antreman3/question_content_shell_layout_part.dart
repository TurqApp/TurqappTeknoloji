part of 'question_content.dart';

extension QuestionContentShellLayoutPart on QuestionContent {
  Widget _buildPageLayout(BuildContext context) {
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
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Obx(() {
                      if (controller.loadingProgress.value < 0.5) {
                        return _buildLoadingState(context);
                      }

                      if (controller.questions.isEmpty) {
                        return Center(child: Text('training.no_questions'.tr));
                      }

                      return _buildQuestionList(context);
                    }),
                  ),
                ],
              ),
              ScrollTotopButton(
                scrollController: _scrollController,
                visibilityThreshold: 500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
