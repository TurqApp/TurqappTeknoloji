part of 'my_practice_exams.dart';

extension MyPracticeExamsContentPart on _MyPracticeExamsState {
  Widget _buildPublishedExamsContent() {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (controller.exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'practice.published_empty'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () => controller.fetchExams(forceRefresh: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.52,
          ),
          itemCount: controller.exams.length,
          itemBuilder: (context, index) {
            return DenemeGrid(
              model: controller.exams[index],
              getData: () async {},
            );
          },
        ),
      ),
    );
  }
}
