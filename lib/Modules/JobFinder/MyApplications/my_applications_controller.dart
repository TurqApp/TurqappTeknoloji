import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MyApplicationsController extends GetxController {
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
    final uid = CurrentUserService.instance.userId;
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
      final uid = CurrentUserService.instance.userId;
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
      final uid = CurrentUserService.instance.userId;
      if (uid.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      batch.delete(FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('myApplications')
          .doc(jobDocID));

      batch.delete(FirebaseFirestore.instance
          .collection(JobCollection.name)
          .doc(jobDocID)
          .collection('Applications')
          .doc(uid));

      batch.update(
          FirebaseFirestore.instance
              .collection(JobCollection.name)
              .doc(jobDocID),
          {'applicationCount': FieldValue.increment(-1)});

      await batch.commit();

      // Prevent negative count
      await _jobRepository.normalizeApplicationCount(jobDocID);

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
