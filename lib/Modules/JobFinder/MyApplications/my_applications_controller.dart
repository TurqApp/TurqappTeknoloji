import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_applications_controller_data_part.dart';
part 'my_applications_controller_actions_part.dart';

class MyApplicationsController extends GetxController {
  static MyApplicationsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyApplicationsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyApplicationsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyApplicationsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyApplicationsController>(tag: tag);
  }

  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
  RxList<JobApplicationModel> applications = <JobApplicationModel>[].obs;
  var isLoading = false.obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapApplicationsImpl());
  }

  Future<void> loadApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadApplicationsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> cancelApplication(String jobDocID) =>
      _cancelApplicationImpl(jobDocID);
}
