part of 'deneme_sinavi_yap.dart';

extension _DenemeSinaviYapContentPart on _DenemeSinaviYapState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Obx(
              () => controller.selection.value == 0
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BackButtons(text: controller.model.sinavAdi),
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: Obx(
                                () => Text(
                                  controller.fullName.value,
                                  style: TextStyles.textFieldTitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(child: _buildExamBody()),
                      ],
                    )
                  : _buildRulesSection(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamBody() {
    return Obx(
      () => controller.isLoading.value
          ? const AppStateView.loading()
          : controller.isInitialized.value && controller.list.isEmpty
              ? AppStateView.empty(
                  title: 'tests.solve_no_questions'.tr,
                  icon: Icons.error_outline,
                )
              : RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  onRefresh: controller.refreshData,
                  child: ListView(
                    children: [
                      Column(
                        children: [
                          for (final ders in controller.model.dersler)
                            _buildLessonSection(ders),
                        ],
                      ),
                      GestureDetector(
                        onTap: controller.setData,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          color: Colors.green,
                          child: Text(
                            'practice.finish_exam'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
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
