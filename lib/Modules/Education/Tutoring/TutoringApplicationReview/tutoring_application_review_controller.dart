import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';

class TutoringApplicationReviewController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final CvRepository _cvRepository = CvRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final String tutoringDocID;
  TutoringApplicationReviewController({required this.tutoringDocID});

  RxList<TutoringApplicationModel> applicants =
      <TutoringApplicationModel>[].obs;
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
      applicants.value = await _tutoringRepository.fetchApplications(
        tutoringDocID,
        preferCache: true,
      );
    } catch (e) {
      print("Özel ders başvuranları yüklenirken hata: $e");
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
      final now = DateTime.now().millisecondsSinceEpoch;
      await _tutoringRepository.updateApplicationStatus(
        tutoringId: tutoringDocID,
        userId: userID,
        status: newStatus,
      );

      final index = applicants.indexWhere((a) => a.userID == userID);
      if (index != -1) {
        final old = applicants[index];
        applicants[index] = TutoringApplicationModel(
          tutoringDocID: old.tutoringDocID,
          userID: old.userID,
          tutoringTitle: old.tutoringTitle,
          tutorName: old.tutorName,
          tutorImage: old.tutorImage,
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
