part of 'create_answer_key.dart';

extension _CreateAnswerKeyDurationPart on _CreateAnswerKeyState {
  Widget _buildDurationOverlay(BuildContext context) {
    return Obx(
      () => controller.showSinavSureleri.value
          ? Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: controller.toggleSinavSureleri,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.00001),
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'answer_key.select_exam_duration'.tr,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: sinavSureleri.length,
                            itemBuilder: (context, index) {
                              final value = sinavSureleri[index];
                              return GestureDetector(
                                onTap: () =>
                                    controller.selectSinavSuresi(value),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Obx(
                                        () => Text(
                                          '$value dk',
                                          style: TextStyle(
                                            color: controller.sinavSuresiCount
                                                        .value ==
                                                    value
                                                ? Colors.indigo
                                                : Colors.black,
                                            fontSize: 18,
                                            fontFamily: controller
                                                        .sinavSuresiCount
                                                        .value ==
                                                    value
                                                ? 'MontserratBold'
                                                : 'MontserratMedium',
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
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
