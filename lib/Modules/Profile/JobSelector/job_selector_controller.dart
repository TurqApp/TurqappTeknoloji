import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/jobs.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'job_selector_controller_facade_part.dart';
part 'job_selector_controller_fields_part.dart';

class JobSelectorController extends GetxController {
  static JobSelectorController ensure({bool permanent = false}) =>
      _ensureJobSelectorController(permanent: permanent);

  static JobSelectorController? maybeFind() =>
      _maybeFindJobSelectorController();

  static const _studentJob = 'öğrenci';
  final _state = _JobSelectorControllerState();

  List<String> _buildInitialJobs() => _buildJobSelectorInitialJobs(this);

  List<String> _initialWithSelected() => _jobSelectorInitialWithSelected(this);

  @override
  void onInit() {
    super.onInit();
    _handleJobSelectorInit(this);
  }

  void selectJob(String value) => _selectJobValue(this, value);

  void filterJobs(String query) => _filterJobOptions(this, query);

  Future<void> setData() => _saveSelectedJob(this);
}
