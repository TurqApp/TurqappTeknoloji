part of 'my_applications.dart';

extension MyApplicationsShellPart on _MyApplicationsState {
  Widget _buildApplicationsBody() {
    if (controller.isLoading.value) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return RefreshIndicator(
      onRefresh: controller.loadApplications,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
        children: [
          if (controller.applications.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: EmptyRow(text: "pasaj.job_finder.no_applications".tr),
            )
          else
            ...controller.applications.map(_applicationCard),
        ],
      ),
    );
  }
}
