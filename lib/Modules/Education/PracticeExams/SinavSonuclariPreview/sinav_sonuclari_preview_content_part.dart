part of 'sinav_sonuclari_preview.dart';

extension SinavSonuclariPreviewContentPart on _SinavSonuclariPreviewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackButtons(text: 'practice.results_title'.tr),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (controller.isInitialized.value &&
                    controller.soruList.isEmpty) {
                  return _buildEmptyState('practice.preview_no_questions'.tr);
                }

                return RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  onRefresh: controller.getYanitlar,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGroupedQuestions(),
                        15.ph,
                        _buildResultsTable(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
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
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedQuestions() {
    return Obx(() {
      final groupedQuestions = <String, List<SoruModel>>{};
      for (final soru in controller.soruList) {
        groupedQuestions.putIfAbsent(soru.ders, () => <SoruModel>[]).add(soru);
      }

      return Column(
        children: groupedQuestions.keys.toList().asMap().entries.map((entry) {
          final colorIndex = entry.key;
          final ders = entry.value;
          var soruIndex = 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => controller.toggleCategory(ders),
                child: Container(
                  height: 45,
                  color: tumderslerColors[colorIndex],
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ders, style: TextStyles.bold18White),
                        Icon(
                          controller.expandedCategories[ders] ?? false
                              ? AppIcons.up
                              : AppIcons.down,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Obx(
                () => controller.expandedCategories[ders] ?? false
                    ? Column(
                        children: groupedQuestions[ders]!.map((soru) {
                          return _buildSoruCard(
                            soru,
                            soruIndex++,
                            controller,
                          );
                        }).toList(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildResultsTable() {
    return Obx(() {
      if (controller.isInitialized.value && controller.dersVeSonuclar.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.black,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'practice.preview_no_results'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 15,
              top: 100,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'practice.lesson_header'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                _buildResultHeader('tests.correct'.tr),
                _buildResultHeader('tests.wrong'.tr),
                _buildResultHeader('tests.blank'.tr),
                _buildResultHeader('tests.net'.tr),
              ],
            ),
          ),
          for (final item in controller.dersVeSonuclar)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.ders, style: TextStyles.medium15Black),
                  ),
                  _buildResultCell(item.dogru.toString()),
                  _buildResultCell(item.yanlis.toString()),
                  _buildResultCell(item.bos.toString()),
                  _buildResultCell(item.net.toString()),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildResultHeader(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  Widget _buildResultCell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyles.regular15Black,
      ),
    );
  }
}
