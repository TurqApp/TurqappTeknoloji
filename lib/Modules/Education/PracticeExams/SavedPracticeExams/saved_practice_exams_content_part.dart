part of 'saved_practice_exams.dart';

extension SavedPracticeExamsContentPart on _SavedPracticeExamsState {
  Widget _buildSavedPracticeExamsContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      if (controller.savedExams.isEmpty) {
        return Center(
          child: Text(
            'practice.saved_empty'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: GridView.builder(
          itemCount: controller.savedExams.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.52,
          ),
          itemBuilder: (context, index) {
            return DenemeGrid(
              model: controller.savedExams[index],
              getData: controller.loadSavedExams,
            );
          },
        ),
      );
    });
  }
}
