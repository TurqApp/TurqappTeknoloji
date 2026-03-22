part of 'booklet_result_preview.dart';

extension _BookletResultPreviewQuestionsPart on _BookletResultPreviewState {
  Widget _buildAnswerRow(int realIndex, int index) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.pink.withValues(
          alpha: index.isEven ? 0.2 : 0.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${realIndex + 1}.',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'MontserratBold',
              ),
            ),
            for (final item in const ['A', 'B', 'C', 'D', 'E'])
              Container(
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _choiceBackgroundColor(realIndex, item),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: _choiceTextColor(realIndex, item),
                    fontSize: 20,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _choiceBackgroundColor(int realIndex, String item) {
    final answer = widget.model.cevaplar[realIndex];
    final correct = widget.model.dogruCevaplar[realIndex];
    if (answer.isEmpty) {
      return correct == item ? Colors.green : Colors.orange;
    }
    if (answer == correct && answer == item) {
      return Colors.green;
    }
    if (answer != correct && correct == item) {
      return Colors.green;
    }
    if (answer == item) {
      return Colors.red;
    }
    return Colors.white;
  }

  Color _choiceTextColor(int realIndex, String item) {
    final answer = widget.model.cevaplar[realIndex];
    if (answer.isEmpty || answer == item) {
      return Colors.white;
    }
    return Colors.black;
  }
}
