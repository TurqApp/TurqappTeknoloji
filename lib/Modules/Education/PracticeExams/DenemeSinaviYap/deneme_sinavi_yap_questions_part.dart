part of 'deneme_sinavi_yap.dart';

extension _DenemeSinaviYapQuestionsPart on _DenemeSinaviYapState {
  Widget _buildLessonSection(String ders) {
    final lessonQuestions =
        controller.list.where((soru) => soru.ders == ders).toList();
    if (lessonQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    var counter = 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          alignment: Alignment.center,
          color: Colors.indigo,
          child: Text(
            ders,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
        ...lessonQuestions.map((soru) {
          final index = counter++;
          return _buildQuestionCard(soru, index);
        }),
      ],
    );
  }

  Widget _buildQuestionCard(SoruModel soru, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'tests.question_number'
                                  .trParams({'index': index.toString()}),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ],
                        ),
                        CachedNetworkImage(
                          imageUrl: soru.soru,
                          errorWidget: (context, url, error) => Text(
                            'practice.question_image_failed'.tr,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              color: Colors.pinkAccent.withValues(alpha: 0.5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: (controller.model.sinavTuru == _practiceExamLgsType
                          ? ['A', 'B', 'C', 'D']
                          : ['A', 'B', 'C', 'D', 'E'])
                      .map((option) {
                    final isSelected = controller
                            .selectedAnswers[controller.list.indexOf(soru)] ==
                        option;
                    return GestureDetector(
                      onTap: () {
                        controller.selectedAnswers[
                            controller.list.indexOf(soru)] = option;
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
