part of 'saved_jobs.dart';

extension SavedJobsShellPart on _SavedJobsState {
  Widget _buildSavedJobsBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [BackButtons(text: "pasaj.job_finder.saved_jobs".tr)],
            ),
          ),
          _buildSavedJobsContent(),
        ],
      ),
    );
  }
}
