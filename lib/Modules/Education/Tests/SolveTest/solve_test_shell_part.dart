part of 'solve_test.dart';

extension _SolveTestShellPart on _SolveTestState {
  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (controller.soruList.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(15),
          child: EmptyRow(text: 'tests.solve_no_questions'.tr),
        );
      }
      return Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: controller.soruList.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader(context);
                  }
                  if (index == controller.soruList.length + 1) {
                    return _buildFinishButton();
                  }
                  return _buildQuestionCard(index - 1);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppBackButton(icon: Icons.arrow_back),
                Obx(
                  () => Text(
                    controller.formatDuration(controller.elapsedTime.value),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Obx(
                () => Text(
                  controller.fullname.value,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    return GestureDetector(
      onTap: controller.testiBitir,
      child: Container(
        height: 50,
        color: Colors.green,
        alignment: Alignment.center,
        child: Text(
          'tests.finish_test'.tr,
          style: TextStyles.medium15white,
        ),
      ),
    );
  }
}
