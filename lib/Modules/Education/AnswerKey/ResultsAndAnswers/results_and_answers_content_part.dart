part of 'results_and_answers.dart';

extension ResultsAndAnswersContentPart on _ResultsAndAnswersState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Obx(
                  () => ListView(
                    children: [
                      _buildScorePanel(),
                      _buildStatsRow(),
                      if (controller.cevaplar.isNotEmpty) _buildAnswersColumn(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          const AppBackButton(icon: Icons.arrow_back),
          const SizedBox(width: 8),
          Expanded(
            child: AppPageTitle(
              model.name,
              fontSize: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        color: Colors.white,
        alignment: Alignment.bottomCenter,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Transform.translate(
              offset: const Offset(0, 60),
              child: Speedometer(
                targetValue: controller.puan.value.toDouble(),
              ),
            ),
            Container(
              width: 80,
              height: 50,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.black),
              child: Text(
                controller.puan.value.toString(),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 35,
                  fontFamily: 'DS',
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            color: Colors.green,
            value: controller.dogruSayisi.value.toString(),
            label: 'tests.correct'.tr,
          ),
        ),
        Expanded(
          child: _buildStatTile(
            color: Colors.red,
            value: controller.yanlisSayisi.value.toString(),
            label: 'tests.wrong'.tr,
          ),
        ),
        Expanded(
          child: _buildStatTile(
            color: Colors.orangeAccent,
            value: controller.bosSayisi.value.toString(),
            label: 'tests.blank'.tr,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersColumn() {
    return Column(
      children: [
        for (int index = 0; index < model.cevaplar.length; index++)
          _buildAnswerRow(index),
      ],
    );
  }

  Widget _buildAnswerRow(int index) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.pink.withAlpha(20)),
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
          for (final item in model.max == 5
              ? ['A', 'B', 'C', 'D', 'E']
              : ['A', 'B', 'C', 'D'])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildAnswerOption(index, item),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(int index, String item) {
    final isSelected = controller.cevaplar[index] == item;
    final isCorrect = model.cevaplar[index] == item;
    final backgroundColor = isSelected
        ? (isCorrect ? Colors.green : Colors.red)
        : (isCorrect ? Colors.white.withValues(alpha: 0.5) : Colors.white);
    final borderColor = isSelected
        ? (isCorrect ? Colors.green : Colors.red)
        : (isCorrect ? Colors.green : Colors.black);

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        item,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 20,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
