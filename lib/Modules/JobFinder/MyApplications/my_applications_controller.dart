import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_application_model.dart';

class MyApplicationsController extends GetxController {
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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('myApplications')
          .orderBy('timeStamp', descending: true)
          .get();

      applications.value = snapshot.docs
          .map((doc) => JobApplicationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Başvurular yüklenirken hata: $e");
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
      final jobSnap = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .doc(jobDocID)
          .get();
      if (jobSnap.exists) {
        final count = (jobSnap.data()?['applicationCount'] ?? 0) as num;
        if (count < 0) {
          await FirebaseFirestore.instance
              .collection(JobCollection.name)
              .doc(jobDocID)
              .update({'applicationCount': 0});
        }
      }

      applications.removeWhere((a) => a.jobDocID == jobDocID);
    } catch (e) {
      print("Başvuru iptal hatası: $e");
    }
  }
}
