import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/jobs.dart';

class JobSelectorController extends GetxController {
  var job = "".obs;
  var filteredJobs = <String>[].obs;
  final UserRepository _userRepository = UserRepository.ensure();
  late final List<String> _initialJobs;
  bool _userInteracted = false;

  List<String> _buildInitialJobs() {
    final idx = jobs.indexWhere((e) => e.trim().toLowerCase() == "öğrenci");
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
    _userRepository
        .getUserRaw(FirebaseAuth.instance.currentUser!.uid)
        .then((data) {
      if (!_userInteracted) {
        job.value = ((data ?? const {})["meslekKategori"] ?? "").toString();
      }
      filteredJobs.assignAll(_initialWithSelected());
    });
  }

  void selectJob(String value) {
    _userInteracted = true;
    job.value = value;
    filteredJobs.refresh();
  }

  void filterJobs(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredJobs.assignAll(_initialWithSelected());
    } else {
      filteredJobs.assignAll(
        jobs.where((job) => job.toLowerCase().contains(q)),
      );
    }
  }

  Future<void> setData() async {
    final selected = job.value.trim();
    if (selected.isEmpty) {
      return;
    }
    await _userRepository.updateUserFields(
      FirebaseAuth.instance.currentUser!.uid,
      {"meslekKategori": selected},
    );

    Get.back();
  }
}
