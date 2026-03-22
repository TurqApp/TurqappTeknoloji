part of 'create_answer_key.dart';

extension _CreateAnswerKeyEditorPart on _CreateAnswerKeyState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'answer_key.create_optical_form_single'.tr),
            _buildEditorBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorBody(BuildContext context) {
    final questionLabelWidth =
        (MediaQuery.of(context).size.width * 0.26).clamp(84.0, 100.0);

    return Expanded(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    itemCount: controller.selections.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHeaderSection(context);
                      }
                      if (index == controller.selections.length + 1) {
                        return _buildFooterSection(context);
                      }
                      return _buildQuestionRow(
                        actualIndex: index - 1,
                        questionLabelWidth: questionLabelWidth,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          _buildDurationOverlay(context),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Container(
            height: 50,
            color: Colors.grey.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  hintText: 'answer_key.give_exam_name'.tr,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'MontserratMedium',
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 7),
              GestureDetector(
                onTap: () => controller.selectDateTime(context),
                child: Container(
                  height: 45,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'answer_key.exam_datetime'.tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'MontserratBold',
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMMM yyyy - HH:mm')
                                .format(controller.selectedDateTime.value),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(),
              GestureDetector(
                onTap: controller.toggleSinavSureleri,
                child: Container(
                  height: 45,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'tests.duration'.tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'MontserratBold',
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${controller.sinavSuresiCount.value} dk',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => PasajSelectionChip(
                  label: 'answer_key.option_answers'.trParams({'count': '5'}),
                  selected: controller.selection.value == 5,
                  onTap: () => controller.setSelection(5),
                  height: 50,
                  borderRadius: BorderRadius.zero,
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => PasajSelectionChip(
                  label: 'answer_key.option_answers'.trParams({'count': '4'}),
                  selected: controller.selection.value == 4,
                  onTap: () => controller.setSelection(4),
                  height: 50,
                  borderRadius: BorderRadius.zero,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: controller.addSelection,
          child: Container(
            height: 70,
            alignment: Alignment.center,
            color: Colors.grey.withValues(alpha: 0.1),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.black,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'answer_key.enter_correct_answers'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => controller.saveForm(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              alignment: Alignment.center,
              child: Text(
                'common.save'.tr,
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
    );
  }

  Widget _buildQuestionRow({
    required int actualIndex,
    required double questionLabelWidth,
  }) {
    final rowColor = actualIndex.isEven
        ? Colors.pink.withValues(alpha: 0.05)
        : Colors.pink.withValues(alpha: 0.12);
    final labelColor = actualIndex.isEven
        ? Colors.pink.withValues(alpha: 0.05)
        : Colors.pink.withValues(alpha: 0.1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: questionLabelWidth,
          height: 50,
          alignment: Alignment.center,
          color: labelColor,
          child: Text(
            '${actualIndex + 1}. Soru',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 50,
            color: rowColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < controller.selection.value; i++)
                      _buildOptionButton(
                        actualIndex: actualIndex,
                        option: const ['A', 'B', 'C', 'D', 'E'][i],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (controller.selections.length > 1)
          GestureDetector(
            onTap: () => controller.removeSelection(actualIndex),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              color: rowColor,
              child: const Icon(
                Icons.remove_circle_outlined,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton({
    required int actualIndex,
    required String option,
  }) {
    final selected = controller.selections[actualIndex] == option;
    return GestureDetector(
      onTap: () => controller.updateSelection(actualIndex, option),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          border: Border.all(
            color: selected ? Colors.green : Colors.black,
          ),
        ),
        child: Text(
          option,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
