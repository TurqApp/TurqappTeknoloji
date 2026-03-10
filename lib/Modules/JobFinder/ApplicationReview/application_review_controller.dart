import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
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
          applicantName: data['applicantName'] ?? '',
          applicantNickname: data['applicantNickname'] ?? '',
          applicantPfImage: data['applicantPfImage'] ?? '',
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
      final doc =
          await FirebaseFirestore.instance.collection('CV').doc(userID).get();
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
      final actorUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (actorUid.isEmpty) {
        AppSnackbar('Hata', 'İşlem için tekrar giriş yapın.');
        return;
      }
      final applicationRef = FirebaseFirestore.instance
          .collection(JobCollection.name)
          .doc(jobDocID)
          .collection('Applications')
          .doc(userID);
      final userApplicationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('myApplications')
          .doc(jobDocID);
      final notificationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('notifications')
          .doc();

      final applicationSnap = await applicationRef.get();
      if (!applicationSnap.exists) {
        AppSnackbar('Hata', 'Başvuru kaydı bulunamadı.');
        return;
      }

      final applicationData =
          applicationSnap.data() ?? const <String, dynamic>{};
      final title = (applicationData['jobTitle'] ?? '').toString().trim();
      final companyName =
          (applicationData['companyName'] ?? '').toString().trim();
      final statusBody = _statusBody(newStatus, title, companyName);

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        applicationRef,
        {
          'status': newStatus,
          'statusUpdatedAt': now,
        },
        SetOptions(merge: true),
      );

      batch.set(
        userApplicationRef,
        {
          'timeStamp': applicationData['timeStamp'] ?? now,
          'jobTitle': applicationData['jobTitle'] ?? '',
          'companyName': applicationData['companyName'] ?? '',
          'companyLogo': applicationData['companyLogo'] ?? '',
          'status': newStatus,
          'statusUpdatedAt': now,
          'userID': userID,
          'applicantName': applicationData['applicantName'] ?? '',
          'applicantNickname': applicationData['applicantNickname'] ?? '',
          'applicantPfImage': applicationData['applicantPfImage'] ?? '',
          'note': applicationData['note'] ?? '',
        },
        SetOptions(merge: true),
      );

      batch.set(notificationRef, {
        'type': 'job_application',
        'fromUserID': actorUid,
        'postID': jobDocID,
        'timeStamp': now,
        'read': false,
        'title': 'Başvuru durumu güncellendi',
        'body': statusBody,
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
          applicantName: old.applicantName,
          applicantNickname: old.applicantNickname,
          applicantPfImage: old.applicantPfImage,
          status: newStatus,
          timeStamp: old.timeStamp,
          statusUpdatedAt: now,
          note: old.note,
        );
        applicants.refresh();
      }
      AppSnackbar('Başarılı', 'Başvuru durumu güncellendi.');
    } catch (e) {
      print("Durum güncelleme hatası: $e");
      AppSnackbar('Hata', 'Başvuru durumu güncellenemedi.');
    }
  }

  String _statusBody(String status, String title, String companyName) {
    final displayTitle = title.isNotEmpty
        ? title
        : companyName.isNotEmpty
            ? companyName
            : 'ilan';

    switch (status) {
      case 'accepted':
        return '$displayTitle başvurun kabul edildi.';
      case 'reviewing':
        return '$displayTitle başvurun incelemeye alındı.';
      case 'rejected':
        return '$displayTitle başvurun reddedildi.';
      default:
        return '$displayTitle başvuru durumun güncellendi.';
    }
  }
}
