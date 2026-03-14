import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/job_application_model.dart';

class MyApplicationsController extends GetxController {
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
  RxList<JobApplicationModel> applications = <JobApplicationModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadApplications();
  }

  Future<void> loadApplications() async {
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final items = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'myApplications',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: true,
        forceRefresh: false,
      );

      applications.value = items
          .map((doc) => JobApplicationModel.fromMap(doc.data, doc.id))
          .toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String jobDocID) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

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
    } catch (_) {
    }
  }
}
