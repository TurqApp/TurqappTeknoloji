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
          ? const Center(child: CupertinoActivityIndicator())
          : controller.isInitialized.value && controller.list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.black,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'tests.solve_no_questions'.tr,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
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
