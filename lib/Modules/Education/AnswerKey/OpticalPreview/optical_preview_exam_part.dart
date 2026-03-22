part of 'optical_preview.dart';

extension OpticalPreviewExamPart on _OpticalPreviewState {
  Widget _buildExamView(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 70,
          color: Colors.white,
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              controller.fullName.text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: model.cevaplar.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: 10,
                          right: 20,
                          top: index == 0 ? 10 : 0,
                        ),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? Colors.pink.withValues(alpha: 0.05)
                                : Colors.pink.withValues(alpha: 0.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 35,
                                height: 35,
                                child: Center(
                                  child: Text(
                                    '${index + 1}.',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                ),
                              ),
                              for (final item in _answerOptions)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () =>
                                        controller.toggleAnswer(index, item),
                                    child: Obx(
                                      () => _buildAnswerBubble(
                                        selected:
                                            controller.cevaplar[index] == item,
                                        label: item,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => controller.handleFinishTest(context),
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        'practice.finish_exam'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
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
    );
  }

  List<String> get _answerOptions => model.max == 5
      ? const ['A', 'B', 'C', 'D', 'E']
      : const ['A', 'B', 'C', 'D'];

  Widget _buildAnswerBubble({
    required bool selected,
    required String label,
  }) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.black,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontSize: 20,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
