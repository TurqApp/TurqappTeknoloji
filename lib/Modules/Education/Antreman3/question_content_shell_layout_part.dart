part of 'question_content.dart';

extension QuestionContentShellLayoutPart on QuestionContent {
  Widget _buildPageLayout(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.onQuestionScreenExit();
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
