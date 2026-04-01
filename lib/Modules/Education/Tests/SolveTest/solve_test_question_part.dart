part of 'solve_test.dart';

extension _SolveTestQuestionPart on _SolveTestState {
  Widget _buildQuestionCard(int questionIndex) {
    final question = controller.soruList[questionIndex];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topLeft,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: CachedNetworkImage(
                  imageUrl: question.img,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CupertinoActivityIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  width: 100,
                  height: 40,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'tests.question_number'.trParams({
                      'index': (questionIndex + 1).toString(),
                    }),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 50,
            color: Colors.pink.withValues(alpha: 0.2),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final choice in const ['A', 'B', 'C', 'D', 'E'])
                    GestureDetector(
                      onTap: () =>
                          controller.updateAnswer(questionIndex, choice),
                      child: Obx(
                        () => Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.cevaplar[questionIndex] == choice
                                ? Colors.black
                                : Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Text(
                            choice,
                            style: TextStyle(
                              color:
                                  controller.cevaplar[questionIndex] == choice
                                      ? Colors.white
                                      : Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
