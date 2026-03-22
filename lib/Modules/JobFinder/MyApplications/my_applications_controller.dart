import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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
    unawaited(_bootstrapApplications());
  }

  Future<void> _bootstrapApplications() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    final cached = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'myApplications',
      orderByField: 'timeStamp',
      descending: true,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      applications.value = cached
          .map((doc) => JobApplicationModel.fromMap(doc.data, doc.id))
          .toList(growable: false);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_applications:$uid',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(loadApplications(silent: true, forceRefresh: true));
      }
      return;
    }
    await loadApplications();
  }

  Future<void> loadApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final items = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'myApplications',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      applications.value = items
          .map((doc) => JobApplicationModel.fromMap(doc.data, doc.id))
          .toList(growable: false);
      SilentRefreshGate.markRefreshed('jobs:my_applications:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String jobDocID) async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;

      await _jobRepository.cancelApplication(
        jobDocId: jobDocID,
        userId: uid,
      );

      applications.removeWhere((a) => a.jobDocID == jobDocID);
      await _subcollectionRepository.setEntries(
        uid,
        subcollection: 'myApplications',
        items: applications
            .map(
              (e) => UserSubcollectionEntry(
                id: e.jobDocID,
                data: e.toMap(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {}
  }
}
