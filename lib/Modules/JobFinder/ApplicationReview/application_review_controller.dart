import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_application_model.dart';

class ApplicationReviewController extends GetxController {
  final String jobDocID;
  ApplicationReviewController({required this.jobDocID});

  RxList<JobApplicationModel> applicants = <JobApplicationModel>[].obs;
  var isLoading = false.obs;

  final RxMap<String, Map<String, dynamic>> cvCache =
      <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadApplicants();
  }

  Future<void> loadApplicants() async {
    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .doc(jobDocID)
          .collection('Applications')
          .orderBy('timeStamp', descending: true)
          .get();

      applicants.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return JobApplicationModel(
          jobDocID: jobDocID,
          userID: doc.id,
          jobTitle: data['jobTitle'] ?? '',
          companyName: data['companyName'] ?? '',
          companyLogo: data['companyLogo'] ?? '',
          status: data['status'] ?? 'pending',
          timeStamp: data['timeStamp'] ?? 0,
          statusUpdatedAt: data['statusUpdatedAt'] ?? 0,
          note: data['note'] ?? '',
        );
      }).toList();
    } catch (e) {
      print("Başvuranlar yüklenirken hata: $e");
    } finally {
      isLoading.value = false;
    }
  }

  static const int _maxCacheSize = 50;

  Future<Map<String, dynamic>?> getApplicantCV(String userID) async {
    if (cvCache.containsKey(userID)) return cvCache[userID];
    try {
      final doc = await FirebaseFirestore.instance
          .collection('CV')
          .doc(userID)
          .get();
      if (doc.exists && doc.data() != null) {
        // Eski cache'i temizle
        if (cvCache.length >= _maxCacheSize) {
          final oldestKey = cvCache.keys.first;
          cvCache.remove(oldestKey);
        }
        cvCache[userID] = doc.data()!;
        return doc.data();
      }
    } catch (e) {
      print("CV yükleme hatası: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      print("Profil yükleme hatası: $e");
    }
    return null;
  }

  Future<void> updateStatus(String userID, String newStatus) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final batch = FirebaseFirestore.instance.batch();

      batch.update(
          FirebaseFirestore.instance
              .collection(JobCollection.name)
              .doc(jobDocID)
              .collection('Applications')
              .doc(userID),
          {
            'status': newStatus,
            'statusUpdatedAt': now,
          });

      batch.update(
          FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .collection('myApplications')
              .doc(jobDocID),
          {
            'status': newStatus,
          });

      await batch.commit();

      final index = applicants.indexWhere((a) => a.userID == userID);
      if (index != -1) {
        final old = applicants[index];
        applicants[index] = JobApplicationModel(
          jobDocID: old.jobDocID,
          userID: old.userID,
          jobTitle: old.jobTitle,
          companyName: old.companyName,
          companyLogo: old.companyLogo,
          status: newStatus,
          timeStamp: old.timeStamp,
          statusUpdatedAt: now,
          note: old.note,
        );
        applicants.refresh();
      }
    } catch (e) {
      print("Durum güncelleme hatası: $e");
    }
  }
}
