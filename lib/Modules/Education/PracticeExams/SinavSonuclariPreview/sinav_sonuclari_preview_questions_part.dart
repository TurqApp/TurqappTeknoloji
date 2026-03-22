part of 'sinav_sonuclari_preview.dart';

extension SinavSonuclariPreviewQuestionsPart on _SinavSonuclariPreviewState {
  Color _determineChoiceColor(
    int index,
    String choice,
    SinavSonuclariPreviewController controller,
  ) {
    if (choice == controller.soruList[index].dogruCevap &&
        controller.yanitlar[index] == '') {
      return Colors.orangeAccent;
    } else if (choice == controller.soruList[index].dogruCevap) {
      return Colors.green;
    } else if (choice == controller.yanitlar[index]) {
      return Colors.red;
    } else {
      return Colors.white;
    }
  }

  Color _determineChoiceTextColor(
    int index,
    String choice,
    SinavSonuclariPreviewController controller,
  ) {
    if (choice == controller.soruList[index].dogruCevap &&
        controller.yanitlar[index] == '') {
      return Colors.white;
    } else if (choice == controller.soruList[index].dogruCevap) {
      return Colors.white;
    } else if (choice == controller.yanitlar[index]) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  Widget _buildChoices(
    SoruModel soru,
    int index,
    SinavSonuclariPreviewController controller,
  ) {
    return Container(
      height: 50,
      color: Colors.pink.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final choice in ['A', 'B', 'C', 'D', 'E'])
              Stack(
                children: [
                  if (choice == soru.dogruCevap)
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
                      color: _determineChoiceColor(index, choice, controller),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        color: _determineChoiceTextColor(
                          index,
                          choice,
                          controller,
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

  Widget _buildSoruCard(
    SoruModel soru,
    int index,
    SinavSonuclariPreviewController controller,
  ) {
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
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: CachedNetworkImage(
                  imageUrl: soru.soru,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                  errorWidget: (context, url, error) => Text(
                    'practice.question_image_failed'.tr,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'tests.question_number'.trParams({
                        'index': index.toString(),
                      }),
                      style: TextStyles.bold18Black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildChoices(soru, index - 1, controller),
        ],
      ),
    );
  }
}
