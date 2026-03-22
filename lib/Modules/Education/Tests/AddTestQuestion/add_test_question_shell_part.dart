part of 'add_test_question.dart';

extension AddTestQuestionShellPart on _AddTestQuestionState {
  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            radius: 20,
                            color: Colors.black,
                          ),
                        )
                      : _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          const AppBackButton(
            icon: Icons.arrow_back_sharp,
            iconColor: Colors.white,
            surfaceColor: Color(0x1FFFFFFF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "tests.add_question".tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
