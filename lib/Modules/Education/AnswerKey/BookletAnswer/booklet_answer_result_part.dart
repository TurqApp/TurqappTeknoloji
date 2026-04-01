part of 'booklet_answer.dart';

extension _BookletAnswerResultPart on _BookletAnswerState {
  Widget _buildResultDialog(BuildContext context) {
    return Obx(
      () => controller.completed.value
          ? Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
                Container(
                  height: (MediaQuery.of(context).size.height * 0.42)
                      .clamp(260.0, 320.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'practice.congrats_title'.tr,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 25,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tests.completed_short'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                height: 1.4,
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.12),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildResultItem(
                                      'tests.correct'.tr,
                                      controller.correctCount.value.toString(),
                                    ),
                                    _buildResultItem(
                                      'tests.wrong'.tr,
                                      controller.wrongCount.value.toString(),
                                    ),
                                    _buildResultItem(
                                      'tests.blank'.tr,
                                      controller.emptyCount.value.toString(),
                                    ),
                                    _buildResultItem(
                                      'tests.net'.tr,
                                      controller.netScore.value
                                          .toStringAsFixed(2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => Text(
                                '${'tests.score'.tr}: ${controller.scorePercent.value.toStringAsFixed(1)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontFamily: 'MontserratMedium',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'common.continue'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Container(),
    );
  }

  Widget _buildResultItem(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ],
    );
  }
}
