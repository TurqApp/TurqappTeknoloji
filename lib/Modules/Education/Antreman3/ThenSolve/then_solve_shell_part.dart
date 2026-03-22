part of 'then_solve.dart';

extension _ThenSolveShellPart on ThenSolve {
  Widget _buildPage(BuildContext context) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            controller.onScreenReEnter();
                            Get.back();
                          },
                          child: BackButtons(
                            text: 'pasaj.question_bank.solve_later'.tr,
                          ),
                        ),
                      ),
                      15.pw,
                    ],
                  ),
                  Expanded(
                    child: Obx(() {
                      if (controller.loadingProgress.value < 0.5) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CupertinoActivityIndicator(),
                              10.ph,
                              Text(
                                'training.questions_loading'.tr,
                                style: const TextStyle(
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
                        return EmptyRow(text: 'training.solve_later_empty'.tr);
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: 1000,
                        itemCount: savedQuestions.length,
                        itemBuilder: (context, index) => _buildQuestionCard(
                          context,
                          savedQuestions[index],
                          index: index,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              ScrollTotopButton(
                scrollController: _scrollController,
                visibilityThreshold: 350,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
