import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/job_application_model.dart';

class ApplicationReviewController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final CvRepository _cvRepository = CvRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
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
      applicants.value = await _jobRepository.fetchApplications(jobDocID);
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
      final data = await _cvRepository.getCv(userID, preferCache: true);
      if (data != null) {
        // Eski cache'i temizle
        if (cvCache.length >= _maxCacheSize) {
          final oldestKey = cvCache.keys.first;
          cvCache.remove(oldestKey);
        }
        cvCache[userID] = data;
        return data;
      }
    } catch (e) {
      print("CV yükleme hatası: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) async {
    try {
      return await _userRepository.getUserRaw(userID);
    } catch (e) {
      print("Profil yükleme hatası: $e");
    }
    return null;
  }

  Future<void> updateStatus(String userID, String newStatus) async {
    try {
      final actorUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (actorUid.isEmpty) {
        AppSnackbar('Hata', 'İşlem için tekrar giriş yapın.');
        return;
      }
      await _jobRepository.updateApplicationStatus(
        jobDocId: jobDocID,
        applicantUserId: userID,
        actorUid: actorUid,
        newStatus: newStatus,
      );

      final index = applicants.indexWhere((a) => a.userID == userID);
      if (index != -1) {
        final old = applicants[index];
        final now = DateTime.now().millisecondsSinceEpoch;
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
      await loadApplicants();
    } catch (e) {
      print("Durum güncelleme hatası: $e");
      AppSnackbar('Hata', 'Başvuru durumu güncellenemedi.');
    }
  }
}
