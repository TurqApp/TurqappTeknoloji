import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/jobs.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class JobSelectorController extends GetxController {
  static JobSelectorController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      JobSelectorController(),
      permanent: permanent,
    );
  }

  static JobSelectorController? maybeFind() {
    if (!Get.isRegistered<JobSelectorController>()) return null;
    return Get.find<JobSelectorController>();
  }

  static const _studentJob = 'öğrenci';
  var job = "".obs;
  var filteredJobs = <String>[].obs;
  final CurrentUserService _userService = CurrentUserService.instance;
  late final List<String> _initialJobs;

  List<String> _buildInitialJobs() {
    final idx = jobs.indexWhere(
      (e) => normalizeSearchText(e) == normalizeSearchText(_studentJob),
    );
    if (idx < 0) {
      return List<String>.from(jobs.take(30));
    }
    return List<String>.from(jobs.take(idx + 1));
  }

  List<String> _initialWithSelected() {
    final current = job.value.trim();
    if (current.isEmpty) {
      return _initialJobs;
    }
    if (_initialJobs.any((e) => e.trim() == current)) {
      return _initialJobs;
    }
    return [current, ..._initialJobs];
  }

  @override
  void onInit() {
    super.onInit();
    _initialJobs = _buildInitialJobs();
    filteredJobs.assignAll(_initialJobs);
    job.value = _userService.meslekKategori.trim();
    filteredJobs.assignAll(_initialWithSelected());
  }

  void selectJob(String value) {
    job.value = value;
    filteredJobs.refresh();
  }

  void filterJobs(String query) {
    final q = normalizeSearchText(query);
    if (q.isEmpty) {
      filteredJobs.assignAll(_initialWithSelected());
    } else {
      filteredJobs.assignAll(
        jobs.where((job) => normalizeSearchText(job).contains(q)),
      );
    }
  }

  Future<void> setData() async {
    final selected = job.value.trim();
    if (selected.isEmpty) {
      return;
    }
    await _userService.updateFields({"meslekKategori": selected});

    Get.back();
  }
}
