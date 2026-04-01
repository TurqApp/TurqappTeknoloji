part of 'sinav_sorusu_hazirla.dart';

extension SinavSorusuHazirlaQuestionPart on _SinavSorusuHazirlaState {
  Widget _buildSinavSorusuHazirlaContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CupertinoActivityIndicator(radius: 20),
        );
      }

      if (controller.isInitialized.value && controller.list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "tests.no_questions_at_all".tr,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: controller.getSorular,
        child: ListView(
          children: [
            Column(
              children: [
                for (var ders in widget.tumDersler)
                  Obx(
                    () => _buildQuestionSection(
                      ders,
                      controller.list
                          .where((soru) => soru.ders == ders)
                          .toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: GestureDetector(
                    onTap: controller.completeExam,
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      color: Colors.green,
                      child: Text(
                        'tests.complete'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuestionSection(String ders, List<SoruModel> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            color: Colors.indigo,
            child: Text(
              ders,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        ),
        questions.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  "tests.no_questions_for_lesson".tr,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                children: questions.asMap().entries.map((entry) {
                  return Column(
                    children: [
                      Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: SoruContent(
                              model: entry.value,
                              sinavTuru: widget.sinavTuru,
                              mainID: widget.docID,
                              index: entry.key,
                              ders: entry.value.ders,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Text(
                              'tests.question_number'
                                  .trParams({'index': '${entry.key + 1}'}),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.grey.withValues(alpha: 0.3)),
                    ],
                  );
                }).toList(),
              ),
      ],
    );
  }
}
