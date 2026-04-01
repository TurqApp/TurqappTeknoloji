part of 'add_test_question.dart';

extension AddTestQuestionContentPart on _AddTestQuestionState {
  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: controller.soruList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.black,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "tests.no_questions_added".tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: controller.soruList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.soruList.length) {
                      return GestureDetector(
                        onTap: controller.addNewQuestion,
                        child: Container(
                          height: 70,
                          alignment: Alignment.center,
                          color: Colors.green,
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildQuestionItem(index);
                  },
                ),
        ),
        GestureDetector(
          onTap: controller.publishTest,
          child: Container(
            height: 50,
            color: Colors.purple,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "post_creator.publish".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionItem(int index) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        CreateTestQuestionContent(
          model: controller.soruList[index],
          testID: controller.testID,
          index: index,
        ),
        GestureDetector(
          onTap: () => controller.deleteQuestion(index),
          child: Transform.translate(
            offset: const Offset(-7, 7),
            child: Container(
              width: 70,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(
                  Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "common.delete".tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
