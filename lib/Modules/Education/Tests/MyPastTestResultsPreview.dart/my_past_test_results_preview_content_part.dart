part of 'my_past_test_results_preview.dart';

extension _MyPastTestResultsPreviewContentPart
    on _MyPastTestResultsPreviewState {
  Widget _buildBody() {
    return Column(
      children: [
        BackButtons(text: 'tests.results_title'.tr),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const AppStateView.loading(title: '');
            }
            if (controller.soruList.isEmpty || controller.yanitlar.isEmpty) {
              return AppStateView.empty(title: 'tests.results_empty'.tr);
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryRow(),
                  for (var index = 0;
                      index < controller.soruList.length;
                      index++)
                    _buildQuestionCard(index),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _buildSummaryTile(
          color: Colors.green,
          value: controller.dogruSayisi.value.toString(),
          label: 'tests.correct'.tr,
        ),
        _buildSummaryTile(
          color: Colors.red,
          value: controller.yanlisSayisi.value.toString(),
          label: 'tests.wrong'.tr,
        ),
        _buildSummaryTile(
          color: Colors.orange,
          value: controller.bosSayisi.value.toString(),
          label: 'tests.blank'.tr,
        ),
        _buildSummaryTile(
          color: Colors.indigo,
          value: '${controller.totalPuan.value.toStringAsFixed(0)}/100',
          label: 'tests.score'.tr,
        ),
      ],
    );
  }

  Widget _buildSummaryTile({
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        height: 60,
        color: color,
        alignment: Alignment.center,
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
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
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
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  top: 15,
                ),
                child: Text(
                  'tests.question_number'.trParams({
                    'index': (index + 1).toString(),
                  }),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: CachedNetworkImage(
              imageUrl: controller.soruList[index].img,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CupertinoActivityIndicator()),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image),
            ),
          ),
          _buildChoices(index),
        ],
      ),
    );
  }
}
