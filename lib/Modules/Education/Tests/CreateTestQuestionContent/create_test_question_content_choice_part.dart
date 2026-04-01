part of 'create_test_question_content.dart';

extension CreateTestQuestionContentChoicePart
    on _CreateTestQuestionContentState {
  Widget _buildChoiceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          controller.model.max.toInt(),
          (i) => _buildChoiceBubble(["A", "B", "C", "D", "E"][i]),
        ),
      ),
    );
  }

  Widget _buildChoiceBubble(String choice) {
    return GestureDetector(
      onTap: () => controller.setCorrectAnswer(choice),
      child: Obx(
        () => Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: controller.model.dogruCevap == choice
                ? Colors.green
                : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: controller.model.dogruCevap == choice
                  ? Colors.green
                  : Colors.black,
            ),
          ),
          child: Text(
            choice,
            style: TextStyle(
              color: controller.model.dogruCevap == choice
                  ? Colors.white
                  : Colors.black,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
