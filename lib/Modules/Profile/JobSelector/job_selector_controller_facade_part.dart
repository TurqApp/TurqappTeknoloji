part of 'job_selector_controller.dart';

const _jobSelectorStudentJob = 'öğrenci';

JobSelectorController ensureJobSelectorController({
  bool permanent = false,
}) =>
    _ensureJobSelectorController(permanent: permanent);

JobSelectorController? maybeFindJobSelectorController() =>
    _maybeFindJobSelectorController();

JobSelectorController _ensureJobSelectorController({
  bool permanent = false,
}) {
  final existing = _maybeFindJobSelectorController();
  if (existing != null) return existing;
  return Get.put(
    JobSelectorController(),
    permanent: permanent,
  );
}

JobSelectorController? _maybeFindJobSelectorController() {
  final isRegistered = Get.isRegistered<JobSelectorController>();
  if (!isRegistered) return null;
  return Get.find<JobSelectorController>();
}

List<String> _buildJobSelectorInitialJobs(JobSelectorController controller) {
  final idx = jobs.indexWhere(
    (e) =>
        normalizeSearchText(e) ==
        normalizeSearchText(
          _jobSelectorStudentJob,
        ),
  );
  if (idx < 0) {
    return List<String>.from(jobs.take(30));
  }
  return List<String>.from(jobs.take(idx + 1));
}

List<String> _jobSelectorInitialWithSelected(JobSelectorController controller) {
  final current = controller.job.value.trim();
  if (current.isEmpty) {
    return controller._initialJobs;
  }
  if (controller._initialJobs.any((e) => e.trim() == current)) {
    return controller._initialJobs;
  }
  return [current, ...controller._initialJobs];
}

void _handleJobSelectorInit(JobSelectorController controller) {
  controller._initialJobs = _buildJobSelectorInitialJobs(controller);
  controller.filteredJobs.assignAll(controller._initialJobs);
  controller.job.value = controller._userService.meslekKategori.trim();
  controller.filteredJobs
      .assignAll(_jobSelectorInitialWithSelected(controller));
}

void _selectJobValue(JobSelectorController controller, String value) {
  controller.job.value = value;
  controller.filteredJobs.refresh();
}

void _filterJobOptions(JobSelectorController controller, String query) {
  final q = normalizeSearchText(query);
  if (q.isEmpty) {
    controller.filteredJobs.assignAll(
      _jobSelectorInitialWithSelected(controller),
    );
    return;
  }
  controller.filteredJobs.assignAll(
    jobs.where((job) => normalizeSearchText(job).contains(q)),
  );
}

Future<void> _saveSelectedJob(JobSelectorController controller) async {
  final selected = controller.job.value.trim();
  if (selected.isEmpty) {
    return;
  }
  await controller._userService.updateFields({"meslekKategori": selected});
  Get.back();
}

extension JobSelectorControllerFacadePart on JobSelectorController {
  void selectJob(String value) => _selectJobValue(this, value);

  void filterJobs(String query) => _filterJobOptions(this, query);

  Future<void> setData() => _saveSelectedJob(this);
}
