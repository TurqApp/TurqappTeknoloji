part of 'application_review.dart';

extension ApplicationReviewShellPart on _ApplicationReviewState {
  Widget _buildApplicationReviewBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.applicants.isEmpty) {
        return const Center(child: CupertinoActivityIndicator());
      }

      if (controller.applicants.isEmpty) {
        return Center(
          child: Text(
            "pasaj.job_finder.no_applicants".tr,
            style: const TextStyle(
              fontFamily: "MontserratMedium",
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.applicants.length,
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
        itemBuilder: (context, index) {
          final app = controller.applicants[index];
          return _applicantCard(app, context);
        },
      );
    });
  }
}
