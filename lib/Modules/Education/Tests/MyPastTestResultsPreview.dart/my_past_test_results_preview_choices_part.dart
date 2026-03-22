part of 'my_past_test_results_preview.dart';

extension _MyPastTestResultsPreviewChoicesPart
    on _MyPastTestResultsPreviewState {
  Widget _buildChoices(int index) {
    return Container(
      height: 50,
      color: Colors.pink.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final choice in const ['A', 'B', 'C', 'D', 'E'])
              Stack(
                children: [
                  if (choice == controller.soruList[index].dogruCevap)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.determineChoiceColor(index, choice),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        color: controller.determineChoiceTextColor(
                          index,
                          choice,
                        ),
                        fontSize: 20,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
