part of 'saved_jobs.dart';

extension SavedJobsContentPart on _SavedJobsState {
  Widget _buildSavedJobsContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CupertinoActivityIndicator(color: Colors.black),
        );
      }

      if (controller.list.isEmpty) {
        return EmptyRow(text: "pasaj.job_finder.no_saved_jobs".tr);
      }

      return Expanded(
        child: ListView.builder(
          itemCount: controller.list.length,
          itemBuilder: (context, index) {
            return JobContent(
              model: controller.list[index],
              isGrid: false,
            );
          },
        ),
      );
    });
  }
}
