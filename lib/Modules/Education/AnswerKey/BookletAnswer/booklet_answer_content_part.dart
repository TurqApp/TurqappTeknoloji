part of 'booklet_answer.dart';

extension _BookletAnswerContentPart on _BookletAnswerState {
  Widget _buildHeader() {
    return Row(children: [BackButtons(text: controller.model.baslik)]);
  }

  Widget _buildQuestionList() {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemCount: controller.model.dogruCevaplar.length + 1,
        itemBuilder: (context, index) {
          if (index == controller.model.dogruCevaplar.length) {
            return Obx(
              () => controller.cevaplar.any(
                (cevap) => const ['A', 'B', 'C', 'D', 'E'].contains(cevap),
              )
                  ? GestureDetector(
                      onTap: controller.finishTest,
                      child: Container(
                        height: 50,
                        color: Colors.green,
                        alignment: Alignment.center,
                        child: Text(
                          'tests.finish_test'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                    )
                  : Container(),
            );
          }

          return _QuestionItem(index: index, controller: controller);
        },
      ),
    );
  }
}

class _QuestionItem extends StatelessWidget {
  final int index;
  final BookletAnswerController controller;

  const _QuestionItem({
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: index.isEven ? 0.2 : 0.4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${index + 1}.',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'MontserratBold',
              ),
            ),
            for (final item in const ['A', 'B', 'C', 'D', 'E'])
              Obx(
                () => GestureDetector(
                  onTap: () => controller.updateAnswer(index, item),
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.cevaplar[index] == item
                          ? Colors.black
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: controller.cevaplar[index] == item
                            ? Colors.white
                            : Colors.black,
                        fontSize: 20,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
