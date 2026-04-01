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
}
